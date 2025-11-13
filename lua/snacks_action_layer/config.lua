local defaults = {
  picker = {
    source = 'action_layer',
    title = 'Actions',
    prompt = '> ',
    layout = 'select',
    format = 'text',
    confirm = 'item_action',
  },
  keymaps = {
    input = {
      ['>'] = { 'action_layer:open', mode = { 'n', 'i' }, nowait = true },
    },
    list = {
      ['>'] = { 'action_layer:open', mode = { 'n' }, nowait = true },
    },
  },
  pickers = {
    default = {
      actions = {},
      order = {},
      keymaps = {},
      metadata = {},
      picker = {},
    },
  },
}

local M = {}

function M.defaults()
  return vim.deepcopy(defaults)
end

local function ensure_defaults(tbl)
  tbl.pickers = tbl.pickers or {}
  tbl.pickers.default = tbl.pickers.default or {}
  local base = tbl.pickers.default
  base.actions = base.actions or {}
  base.order = base.order or {}
  base.keymaps = base.keymaps or {}
  base.metadata = base.metadata or {}
  base.picker = base.picker or {}
end

function M.merge(user_opts)
  local merged = vim.tbl_deep_extend('force', vim.deepcopy(defaults), user_opts or {})
  ensure_defaults(merged)
  return merged
end

return M
