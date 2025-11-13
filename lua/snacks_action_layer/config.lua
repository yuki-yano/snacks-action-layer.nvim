local defaults = {
  picker = {
    source = 'action_layer',
    title = 'Actions',
    prompt = '> ',
    layout = 'select',
    format = 'text',
    confirm = 'item_action',
  },
  pickers = {},
}

local M = {}

function M.defaults()
  return vim.deepcopy(defaults)
end

local function ensure_defaults(tbl)
  tbl.pickers = tbl.pickers or {}
end

function M.merge(user_opts)
  local merged = vim.tbl_deep_extend('force', vim.deepcopy(defaults), user_opts or {})
  ensure_defaults(merged)
  return merged
end

return M
