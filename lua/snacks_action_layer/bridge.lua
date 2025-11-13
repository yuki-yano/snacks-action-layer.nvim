local M = {}

local function picker_name_from(picker)
  if picker and picker.source and picker.source.name then
    return picker.source.name
  end
  if picker and picker.opts and picker.opts.source then
    return picker.opts.source
  end
  return 'default'
end

local function has_existing_key(existing_picker, source, section, key)
  if not existing_picker then
    return false
  end
  local sources = existing_picker.sources or {}
  local source_conf = sources[source]
  if not source_conf then
    return false
  end
  local win = source_conf.win or {}
  local section_conf = win[section] or {}
  local keys = section_conf.keys or {}
  return keys[key] ~= nil
end

local function merge_keymaps(config, picker_name)
  local sections = { 'input', 'list' }
  local resolved = {}
  local pickers = config.pickers or {}
  local default_conf = pickers.default or {}
  local picker_conf = pickers[picker_name] or {}
  for _, section in ipairs(sections) do
    resolved[section] = vim.tbl_deep_extend(
      'force',
      {},
      (config.keymaps and config.keymaps[section]) or {},
      (default_conf.keymaps and default_conf.keymaps[section]) or {},
      (picker_conf.keymaps and picker_conf.keymaps[section]) or {}
    )
  end
  return resolved
end

local function add_keymap(target, section, key, mapping)
  target.win = target.win or {}
  target.win[section] = target.win[section] or {}
  target.win[section].keys = target.win[section].keys or {}
  target.win[section].keys[key] = vim.deepcopy(mapping)
end

function M.build_overrides(config, existing_picker)
  local overrides = {
    picker = {
      actions = {},
      sources = {},
    },
  }

  overrides.picker.actions['action_layer:open'] = function(picker)
    local ok, picker_mod = pcall(require, 'snacks_action_layer.picker')
    if not ok then
      vim.notify_once('[snacks-action-layer] picker module is unavailable', vim.log.levels.ERROR)
      return
    end
    picker_mod.open(picker, picker_name_from(picker), config)
  end

  local pickers = config.pickers or {}
  for name in pairs(pickers) do
    if name ~= 'default' then
      local keymaps = merge_keymaps(config, name)
      local source_entry
      for section, mappings in pairs(keymaps) do
        for key, mapping in pairs(mappings or {}) do
          if mapping ~= false and not has_existing_key(existing_picker, name, section, key) then
            source_entry = source_entry or { win = {} }
            add_keymap(source_entry, section, key, mapping)
          end
        end
      end
      if source_entry then
        overrides.picker.sources[name] = source_entry
      end
    end
  end

  return overrides
end

return M
