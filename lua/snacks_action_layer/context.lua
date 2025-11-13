local M = {}

local function call_picker_selected(picker)
  if not picker or type(picker.selected) ~= 'function' then
    return {}
  end
  local ok, result = pcall(function()
    return picker:selected({ fallback = true })
  end)
  if not ok or type(result) ~= 'table' then
    return {}
  end
  return result
end

function M.sanitize_selection(picker, selection)
  local source = selection or call_picker_selected(picker)
  local sanitized = {}
  for _, item in ipairs(source or {}) do
    if type(item) == 'table' then
      sanitized[#sanitized + 1] = vim.deepcopy(item)
    end
  end
  return sanitized
end

function M.build_summary(items)
  local lines = {}
  for _, item in ipairs(items or {}) do
    local text = item.status or item.text or item.value
    if text == nil then
      if item.file then
        text = item.file
      elseif item.cwd then
        text = item.cwd
      end
    end
    if text ~= nil then
      lines[#lines + 1] = tostring(text)
    end
  end
  return table.concat(lines, '\n')
end

local function resolve_metadata(config, picker_name, action_conf)
  local pickers = config.pickers or {}
  local default_meta = (pickers.default and pickers.default.metadata) or {}
  local picker_meta = (pickers[picker_name] and pickers[picker_name].metadata) or {}
  local action_meta = action_conf.metadata or {}
  return vim.tbl_deep_extend('force', {}, default_meta, picker_meta, action_meta)
end

function M.make_ctx(picker, picker_name, items, action_conf, config)
  local summary = M.build_summary(items)
  local metadata = resolve_metadata(config, picker_name, action_conf)

  local function close_picker()
    if picker and not picker.closed and type(picker.close) == 'function' then
      picker:close()
    end
  end

  local function focus_list()
    if picker and not picker.closed and type(picker.focus) == 'function' then
      picker:focus('list', { show = true })
    end
  end

  return {
    picker = picker,
    picker_name = picker_name,
    items = items,
    summary = summary,
    metadata = metadata,
    close_picker = close_picker,
    focus_list = focus_list,
  }
end

return M
