# stackmap.nvim

Stacks of maps

## Overview

A plugin for easily adding and then removing sets of mappings without losing
what maps you had before.

## Installation

You can install it through your favorite plugin manager:

<details>
<summary><a href="https://github.com/folke/lazy.nvim">lazy.nvim</a></summary>

```lua
{ "Alighorab/stackmap.nvim" }
```

</details>

<details>
<summary><a href="https://github.com/wbthomason/packer.nvim">packer.nvim</a></summary>

```lua
use({ "Alighorab/stackmap.nvim" })
```

</details>

## Usage

To create/push a keymaps at some event, suppose you have the keybindings
`<leader>st` and `<leader>St` mapped to something and you want to map them to
another for a short period of time (e.g., on `dap` open) and then restoring
them after it finishes, you can do this

```lua
on_event_x(function()
  require("stackmap").push("event_x", "n", {
    { "<leader>st", "echo 'Wow, this got mapped!", { silent = true } }, -- same syntax as `vim.keymap.set`
    { 
      "<leader>St",
      "echo 'Wow, this got mapped too!", {
        buffer = vim.api.nvim_get_current_buf() 
      }
    },
  })
end)
```

and to restore them back

```lua
after_event_x(function()
  require("stackmap").pop("event_x", "n")
end)
```

## Features

Pushing multiple mappings

<details>
<summary>Example</summary>

```lua
local rhs = "echo 'This is a test'"
require("stackmap").push("test1", "n", {
  { "asdf_1", rhs .. "1" },
  { "asdf_2", rhs .. "2" },
})

-- and then you can restore them
require("stackmap").pop("test1", "n")
```
</details>

Restoring mappings options

<details>
<summary>Example</summary>

```lua
vim.keymap.set("n", "asdf_1", "echo 'OG MAPPING'", {
  silent = 1,
  desc = "Mapping description",
})

local rhs = "echo 'This is a test'"
require("stackmap").push("test1", "n", {
  { "asdf_1", rhs },
})

require("stackmap").pop("test1", "n")
```
</details>

Handling buffer mappings

<details>
<summary>Example</summary>

```lua
local bufnr = vim.api.nvim_get_current_buf()
vim.keymap.set("n", "asdfasdf", "echo 'OG MAPPING'", {
  silent = 1,
  desc = "description",
  buffer = bufnr,
})

local rhs = "echo 'This is a test'"
require("stackmap").push("test1", "n", {
  { "asdfasdf", rhs },
})

require("stackmap").pop("test1", "n")
```
</details>


Handling muliple calls with the same group name

<details>
<summary>Example</summary>

```lua
local rhs = "echo 'OG MAPPING'"
vim.keymap.set("n", "asdfasdf", rhs)

local rhs_1 = "echo 'This is a test 1'"
require("stackmap").push("test1", "n", {
  { "asdfasdf", rhs_1 },
})

local rhs_2 = "echo 'This is a test 2'"
require("stackmap").push("test1", "n", {
  { "asdfasdf", rhs_2 }, -- overrides the previous map and now it's gone
})

require("stackmap").pop("test1", "n")
```
</details>


Nested keymaps

<details>
<summary>Example</summary>

```lua
-- Suppose you have this mapped somewhere in your config or by some plugin
local rhs = "echo 'OG MAPPING'"
vim.keymap.set("n", "asdfasdf", rhs, { 
  silent = true,
  desc = "Original mapping"
})

-- And then some event starts, and you pushed this mapping
local rhs_1 = "echo 'This is a test 1'"
require("stackmap").push("test1", "n", {
  { "asdfasdf", rhs_1 },
})

-- then, another event starts and toke over this map
local rhs_2 = "echo 'This is a test 2'"
require("stackmap").push("test2", "n", {
  { "asdfasdf", rhs_2 },
})

-- you must (by definition) pop the last in first
require("stackmap").pop("test2", "n")
require("stackmap").pop("test1", "n")
```
</details>

## Example

You can use `stackmap-nvim` to emulate `lsp` on_attch function in [`dap`] by
using dap listeners so that your debugger keymaps be active only when [`dap`]
starts:  
```lua
dap.listeners.after["event_initialized"]["me"] = function()
  push("debug_mode", "n", {
    {
      "<F7>",
      function(_)
        dap.terminate(_, _, function()
          dap.repl.close()
          dapui.close()
        end)
      end,
      { desc = "Dap terminate" },
    },
    { "<F10>", dap.step_over, { desc = "Dap step over" } },
    { "<F11>", dap.step_into, { desc = "Dap step into" } },
    { "<F12>", dap.step_out, { desc = "Dap step out" } },
    { "<leader>rc", dap.run_to_cursor, { desc = "Dap run to cursor" } },
    { "<leader>dp", dap.pause, { desc = "Dap pause" } },
    { "K", require("dap.ui.widgets").hover, { desc = "Dap hover" } },
  })
end

dap.listeners.after["event_terminated"]["me"] = function()
  pop("debug_mode", "n")
end
```

[`dap`]: https://github.com/mfussenegger/nvim-dap
