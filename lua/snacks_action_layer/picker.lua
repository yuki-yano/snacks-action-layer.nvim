local context = require('snacks_action_layer.context')

local M = {}

local function get_picker_config(config, picker_name)
  local pickers = config.pickers or {}
  local merged = vim.tbl_deep_extend(
    'force',
    {},
    config.picker or {},
    (pickers.default and pickers.default.picker) or {},
    (pickers[picker_name] and pickers[picker_name].picker) or {}
  )
  merged.source = merged.source or 'action_layer'
  merged.confirm = merged.confirm or 'item_action'
  merged.layout = merged.layout or 'select'
  merged.format = merged.format or 'text'
  merged.prompt = merged.prompt or '> '
  merged.title = merged.title or 'Actions'
  return merged
end

local function merge_actions(base, overrides)
  local result = {}
  for id, action in pairs(base or {}) do
    if type(action) == 'table' then
      result[id] = action
    end
  end
  for id, action in pairs(overrides or {}) do
    if type(action) == 'table' then
      result[id] = action
    end
  end
  return result
end

local function collect_order(defaults, specific)
  local order = {}
  for _, id in ipairs(defaults or {}) do
    if type(id) == 'string' then
      order[#order + 1] = id
    end
  end
  for _, id in ipairs(specific or {}) do
    if type(id) == 'string' then
      order[#order + 1] = id
    end
  end
  return order
end

function M.resolve_actions(picker_name, config)
  local pickers = config.pickers or {}
  local default_conf = pickers.default or {}
  local picker_conf = pickers[picker_name] or {}
  local combined = merge_actions(default_conf.actions, picker_conf.actions)

  local filtered = {}
  for id, action_conf in pairs(combined) do
    if type(action_conf) == 'table' then
      local enabled = action_conf.enabled
      if enabled == nil or enabled then
        filtered[id] = action_conf
      end
    end
  end

  local order = collect_order(default_conf.order, picker_conf.order)
  local ordered = {}
  local seen = {}
  for _, id in ipairs(order) do
    local conf = filtered[id]
    if conf then
      ordered[#ordered + 1] = { id = id, config = conf }
      seen[id] = true
    end
  end

  local remaining = {}
  for id in pairs(filtered) do
    if not seen[id] then
      remaining[#remaining + 1] = id
    end
  end
  table.sort(remaining)
  for _, id in ipairs(remaining) do
    ordered[#ordered + 1] = { id = id, config = filtered[id] }
  end

  return ordered
end

local function resolve_preview(preview, ctx, action_id)
  local value = preview
  if type(value) == 'function' then
    local ok, result = pcall(value, ctx)
    if ok then
      value = result
    else
      value = nil
      vim.notify(result, vim.log.levels.ERROR, {
        title = ('snacks-action-layer preview (%s)'):format(action_id),
      })
    end
  end
  if value == nil then
    value = ctx.summary
  end
  if type(value) == 'string' then
    return { text = value }
  elseif type(value) == 'table' then
    return value
  elseif value ~= nil then
    return { text = tostring(value) }
  end
  return { text = ctx.summary }
end

local function wrap_handler(action_id, action_conf, ctx)
  if type(action_conf.handler) ~= 'function' then
    return nil
  end
  return function()
    local ok, err = pcall(action_conf.handler, ctx)
    if not ok then
      vim.notify(err, vim.log.levels.ERROR, {
        title = ('snacks-action-layer (%s)'):format(action_id),
      })
    end
  end
end

function M.build_action_items(actions, picker, picker_name, items, config)
  local list = {}
  for _, entry in ipairs(actions) do
    local action_id = entry.id
    local action_conf = entry.config or {}
    local ctx = context.make_ctx(picker, picker_name, items, action_conf, config)
    local handler = wrap_handler(action_id, action_conf, ctx)
    if handler then
      list[#list + 1] = {
        text = action_conf.label or action_id,
        value = action_id,
        action_id = action_id,
        action = handler,
        preview = resolve_preview(action_conf.preview, ctx, action_id),
      }
    end
  end
  return list
end

local function get_target_ref(picker)
  if picker and type(picker.ref) == 'function' then
    local ok, ref = pcall(function()
      return picker:ref()
    end)
    if ok then
      return ref
    end
  end
  return nil
end

local function restore_focus(target_ref, picker, prev_auto_close)
  local target = (target_ref and target_ref()) or picker
  if target and target.opts then
    target.opts.auto_close = prev_auto_close
  end
  if target and not target.closed and type(target.focus) == 'function' then
    target:focus('list', { show = true })
  end
end

function M.open(picker, picker_name, config)
  local ok_snacks, snacks = pcall(require, 'snacks')
  if not ok_snacks then
    vim.notify_once('[snacks-action-layer] snacks.nvim is not available', vim.log.levels.WARN)
    return
  end

  local items = context.sanitize_selection(picker)
  if vim.tbl_isempty(items) then
    return
  end

  local actions = M.resolve_actions(picker_name, config)
  if #actions == 0 then
    return
  end

  local action_items = M.build_action_items(actions, picker, picker_name, items, config)
  if #action_items == 0 then
    return
  end

  local prev_auto_close = picker and picker.opts and picker.opts.auto_close
  if picker and picker.opts then
    picker.opts.auto_close = false
  end

  local target_ref = get_target_ref(picker)
  local picker_opts = get_picker_config(config, picker_name)
  picker_opts.items = action_items
  picker_opts.on_close = function()
    restore_focus(target_ref, picker, prev_auto_close)
  end

  snacks.picker.pick(picker_opts)
end

return M
