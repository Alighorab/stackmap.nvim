local M = {}

-- M.setup = function(opts)
--   print("Options:", opts)
-- end

-- functions we need:
-- - vim.keymap.set(...) -> create new keymaps
-- - nvim_get_keymap

-- vim.api.nvim_get_keymap(...)

local find_mapping = function(maps, lhs)
  -- pairs
  --    iterates over EVERY key in a table
  --    order not guaranteed
  -- ipairs
  --    iteratres over ONLY numeric keys in a table
  --    order IS guaranteed
  for _, value in ipairs(maps) do
    if value.lhs == lhs then
      return value
    end
  end
end

M._stack = {}

M.push = function(group, mode, mappings)
	M._stack[group] = M._stack[group] or {}
	M._stack[group][mode] = M._stack[group][mode] or { existing = {}, mappings = {} }

	local bufnr = vim.api.nvim_get_current_buf()
	local global_keymaps = vim.api.nvim_get_keymap(mode)
	local buffer_keymaps = vim.api.nvim_buf_get_keymap(bufnr, mode)
	local previous_keymaps = M._stack[group][mode].mappings or {}
	local keymaps = vim.tbl_extend("force", global_keymaps, buffer_keymaps, previous_keymaps)

	local existing_keymaps = {}
	for _, map in ipairs(mappings) do
		local lhs = map[1] or nil
		local rhs = map[2] or nil
		local opts = vim.deepcopy(map[3] or {})

		vim.validate({
			map = { map, "t" },
			lhs = { lhs, "s" },
			rhs = { rhs, { "s", "f" } },
			opts = { opts, "t", true },
		})

		local existing = find_mapping(keymaps, lhs)
		if existing then
			table.insert(existing_keymaps, existing)
			if existing.buffer ~= 0 then
				vim.keymap.del(mode, existing.lhs, { buffer = existing.buffer })
			else
				vim.keymap.del(mode, existing.lhs)
			end
		end
		vim.keymap.set(mode, lhs, rhs, opts)
	end

	-- Handle multiple calls to push with the same group and mode
	M._stack[group][mode].existing = vim.tbl_extend("keep", M._stack[group][mode].existing, existing_keymaps)
	M._stack[group][mode].mappings = vim.tbl_extend("force", M._stack[group][mode].mappings, mappings)
end

M.pop = function(name, mode)
  local state = M._stack[name][mode]
  M._stack[name][mode] = nil

  for lhs in pairs(state.mappings) do
    if state.existing[lhs] then
      -- Handle mappings that existed
      local og_mapping = state.existing[lhs]

      -- TODO: Handle the options from the table
      vim.keymap.set(mode, lhs, og_mapping.rhs)
    else
      -- Handled mappings that didn't exist
      vim.keymap.del(mode, lhs)
    end
  end
end

--[[
lua require("mapstack").push("debug_mode", "n", {
  ["<leader>st"] = "echo 'Hello'",
  ["<leader>sz"] = "echo 'Goodbye'",
})

...

push "debug"
push "other"
pop "debug"
pop "other

lua require("mapstack").pop("debug_mode")
--]]

M._clear = function()
  M._stack = {}
end

return M
