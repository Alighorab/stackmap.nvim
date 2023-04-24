local M = {}

local find_mapping = function(maps, lhs)
	lhs = string.gsub(lhs, "<leader>", vim.g.mapleader or " ")
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
	local state = M._stack[name][mode] or { existing = {}, mappings = {} }
	M._stack[name][mode] = nil

	for _, map in pairs(state.mappings) do
		local og_map = find_mapping(state.existing, map[1])
		if og_map then
			local lhs = og_map.lhs
			local rhs = og_map.callback or og_map.rhs
			local opts = {
				noremap = og_map.noremap,
				silent = og_map.silent,
				script = og_map.script,
				nowait = og_map.nowait,
				unique = og_map.unique,
				desc = og_map.desc,
			}

			if og_map.buffer ~= 0 then
				opts.buffer = og_map.buffer
				vim.keymap.del(mode, og_map.lhs)
			end

			vim.keymap.set(mode, lhs, rhs, opts)
		else
			vim.keymap.del(mode, map[1])
		end
	end
end

M._clear = function()
	M._stack = {}
end

return M
