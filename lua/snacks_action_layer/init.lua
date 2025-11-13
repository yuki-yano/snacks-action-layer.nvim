local config_mod = require('snacks_action_layer.config')
local bridge = require('snacks_action_layer.bridge')

local M = {
  _config = config_mod.defaults(),
}

local function merge_picker_opts(target, overrides)
  if not overrides then
    return target or {}
  end
  if not target then
    return vim.deepcopy(overrides)
  end
  return vim.tbl_deep_extend('force', target, overrides)
end

function M.setup(opts, snacks_opts)
  local config = config_mod.merge(opts)
  M._config = config

  local existing_picker = snacks_opts and snacks_opts.picker or nil
  local overrides = bridge.build_overrides(config, existing_picker)

  if snacks_opts then
    snacks_opts.picker = merge_picker_opts(snacks_opts.picker or {}, overrides.picker)
    return snacks_opts
  end

  local ok = pcall(require, 'snacks')
  if not ok then
    vim.notify_once('[snacks-action-layer] snacks.nvim is not installed; returning overrides only', vim.log.levels.WARN)
  end

  return overrides
end

function M.spec(opts)
  return {
    'folke/snacks.nvim',
    opts = function(_, snacks_opts)
      require('snacks_action_layer').setup(opts, snacks_opts)
    end,
  }
end

function M.get_config()
  return M._config
end

return M
