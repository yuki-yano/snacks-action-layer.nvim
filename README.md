# snacks-action-layer.nvim

Snacks Action Layer augments any [snacks.nvim](https://github.com/folke/snacks.nvim) picker with a secondary picker that lists custom actions for the currently selected entries. It lets you keep the original picker visible, inspect the selection, and trigger reusable handlers such as Git helpers or buffer/window commands.

## Requirements

- Neovim 0.9+
- snacks.nvim 0.5+

## Installation

### lazy.nvim (config hook)

```lua
{
  'yuki-yano/snacks-action-layer.nvim',
  dir = '~/repos/github.com/yuki-yano/snacks-action-layer.nvim', -- optional local dev
}

{
  'folke/snacks.nvim',
  config = function()
    local snacks_opts = {
      picker = {
        -- your Snacks setup
      },
    }

    require('snacks_action_layer').setup({
      pickers = {
        git_status = {
          actions = require('user.git_actions'),
        },
      },
    }, snacks_opts)

    require('snacks').setup(snacks_opts)
  end,
}
```

If you prefer a single spec, use the helper: `return require('snacks_action_layer').spec(opts)`.

## Configuration Reference

```lua
require('snacks_action_layer').setup({
  picker = {       -- global action picker defaults
    source = 'action_layer',
    title = 'Actions',
    prompt = '> ',
    layout = 'select',
    format = 'text',
    confirm = 'item_action',
  },
  keymaps = {      -- define your own keymaps; nothing is injected by default
    input = {
      -- ['>'] = { 'action_layer:open', mode = { 'n', 'i' }, nowait = true },
    },
    list = {
      -- ['>'] = { 'action_layer:open', mode = { 'n' }, nowait = true },
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
    git_status = { -- Snacks source name
      actions = { ... },
      order = { ... },
      keymaps = { ... },
      metadata = { ... },
      picker = { ... },
    },
  },
})
```

- `pickers.default` acts as the base for every source. Values in `pickers.<name>` override it. The plugin ships with no builtin actions (Git or otherwise); you decide every handler.
- Keymaps are merged in this order: global `keymaps` → `pickers.default.keymaps` → `pickers.<name>.keymaps`. Keys marked as `false` are omitted. Existing `snacks_opts.picker.sources[name].win.*.keys[key]` entries are never overwritten. Keymaps are injected only for sources explicitly defined in `pickers` (other than `default`). By default no keymaps are inserted, so make sure to define your preferred binding for `action_layer:open` yourself.
- `actions` entries look like:

```lua
actions = {
  example = {
    label = 'Echo selection',
    handler = function(ctx)
      vim.notify(ctx.summary)
      ctx.focus_list()
    end,
    preview = function(ctx)
      return { text = ctx.summary }
    end,
  },
}
order = { 'example' }
```

`order` controls the listing sequence. Any action IDs not listed there are appended alphabetically.

### Action Context (`ctx`)

Every handler receives the same context table:

| Field | Description |
| --- | --- |
| `picker` | The original Snacks picker instance. |
| `picker_name` | Source name (`git_status`, `files`, etc.). |
| `items` | Deep copy of `picker:selected({ fallback = true })`. |
| `summary` | Human-readable string built from `status`, `text`, or `value`. |
| `metadata` | Merged metadata (`action` → picker-specific → default). |
| `close_picker()` | Closes the source picker (useful for commands that open other UI). |
| `focus_list()` | Moves focus back to the original picker list. |

### Metadata merge order

`action.metadata` overrides `pickers[picker_name].metadata`, which overrides `pickers.default.metadata`. Missing tables are treated as `{}`.

## Sample Actions

### Optional Git example

```lua
pickers = {
  git_status = {
    actions = {
      stage = {
        label = 'Add (git add)',
        handler = function(ctx)
          for _, item in ipairs(ctx.items) do
            local file = item.file or item.text
            if file then
              vim.system({ 'git', 'add', '--', file }, { cwd = item.cwd })
            end
          end
          ctx.focus_list()
        end,
      },
      patch = {
        label = 'Patch (:GinPatch)',
        handler = function(ctx)
          ctx.close_picker()
          vim.schedule(function()
            for _, item in ipairs(ctx.items) do
              vim.cmd(('GinPatch %s'):format(vim.fn.fnameescape(item.file or '')))
            end
          end)
        end,
      },
    },
    order = { 'stage', 'patch' },
  },
}
```

### Files picker splittings

```lua
pickers = {
  files = {
    actions = {
      vsplit = {
        label = 'Open in vsplit',
        handler = function(ctx)
          ctx.close_picker()
          vim.schedule(function()
            for _, item in ipairs(ctx.items) do
              vim.cmd('vsplit ' .. vim.fn.fnameescape(item.file or item.text or ''))
            end
          end)
        end,
      },
      tab = {
        label = 'Open in tab',
        handler = function(ctx)
          ctx.close_picker()
          vim.schedule(function()
            for _, item in ipairs(ctx.items) do
              vim.cmd('tabedit ' .. vim.fn.fnameescape(item.file or item.text or ''))
            end
          end)
        end,
      },
    },
  },
}
```

### Grep → quickfix

```lua
pickers = {
  grep = {
    actions = {
      quickfix = {
        label = 'Send to quickfix',
        handler = function(ctx)
          local items = {}
          for _, item in ipairs(ctx.items) do
            items[#items + 1] = {
              filename = item.file,
              lnum = item.lnum,
              col = item.col,
              text = item.text,
            }
          end
          vim.fn.setqflist(items)
          ctx.focus_list()
        end,
      },
    },
  },
}
```

## Future Work

- Support other picker frameworks by exposing a neutral bridge interface.
- Provide optional tests for common action adapters.
- Document additional action recipes contributed by users.

## License

Distributed under the MIT License. See [LICENSE](LICENSE).
