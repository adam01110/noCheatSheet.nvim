# noCheatSheet.nvim

Standalone extraction of NvChad's cheatsheet UI.

This keeps the auto-generated keymap cheatsheet from `nvchad/ui`, but removes the runtime dependency on the rest of NvChad UI and `base46`.

![noCheatSheet.nvim](https://nvchad.com/features/nvcheatsheet.webp)

## Features

- Provides the `:Cheatsheet` command.
- Builds sections from current Neovim keymap descriptions.
- Supports the original `grid` and `simple` layouts.
- Derives explicit highlight colors from your active colorscheme instead of using generated `base46` cache files.
- Does not require `nvchad/base46`, `nvchad/volt`, statusline, tabline, dashboard, cmp UI, mason helpers, or telescope extensions.

## Install

With `lazy.nvim`:

```lua
{
  "adam01110/noCheatSheet.nvim",
  main = "nocheatsheet",
  cmd = "Cheatsheet",
  opts = {},
}
```

Then run:

```vim
:Cheatsheet
```

## Configure

Pass options through your plugin spec:

```lua
{
  "adam01110/noCheatSheet.nvim",
  main = "nocheatsheet",
  cmd = "Cheatsheet",
  opts = {
    theme = "grid", -- "grid" or "simple"
    excluded_groups = { "terminal (t)", "autopairs", "Nvim", "Opens" },
    highlights = {
      -- Override any NoCheatSheet... highlight group here.
      -- Values can be highlight links or nvim_set_hl() specs.
      NoCheatSheetSection = { fg = 0xd8dee9, bg = 0x2e3440 },
    },
  },
}
```

Or configure it manually:

```lua
require("nocheatsheet").setup {
  theme = "simple",
  excluded_groups = {},
}
```

## Lazy Loading

Command-based lazy loading is the recommended setup because the plugin only needs to collect mappings when the cheatsheet is opened:

```lua
{
  "adam01110/noCheatSheet.nvim",
  main = "nocheatsheet",
  cmd = "Cheatsheet",
  opts = {},
}
```

If you want a keymap, let `lazy.nvim` load the plugin from the key instead of using an event:

```lua
{
  "adam01110/noCheatSheet.nvim",
  main = "nocheatsheet",
  cmd = "Cheatsheet",
  keys = {
    { "<leader>?", "<cmd>Cheatsheet<CR>", desc = "Open cheatsheet" },
  },
  opts = {},
}
```

Avoid event-based loading like `VeryLazy`, `BufReadPost`, or `VimEnter` unless you specifically want the command registered eagerly. It adds startup work without improving the cheatsheet behavior.

## Health Check

Run:

```vim
:checkhealth nocheatsheet
```

This checks module loading, setup availability, theme validity, command registration, and whether the main card/header highlights have backgrounds.

## Compatibility

This fork intentionally does not keep NvChad-compatible names.

- Use `require("nocheatsheet")`, not `require("nvchad")`.
- Use `:Cheatsheet`, not `:NvCheatsheet`.
- Configure with `setup()` or plugin-manager `opts`, not `chadrc.lua` or `nvconfig.lua`.
- Highlight groups use `NoCheatSheet...` names, not `NvCh...` names.

Keymaps are grouped by the first word of their `desc` field. For example:

```lua
vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<CR>", { desc = "File find" })
```

This appears under the `File` section as `Find`.

> [!NOTE]
> Mappings without a multi-word `desc`, mappings with newlines in `desc`, and `<Plug>` mappings are skipped.

## Credits

This project is based on the cheatsheet module from [`nvchad/ui`](https://github.com/NvChad/ui).
