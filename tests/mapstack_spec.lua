local find_map = function(lhs, bufnr)
  local maps = vim.api.nvim_get_keymap("n")
  local buffer_keymaps = {}
  if bufnr then
    buffer_keymaps = vim.api.nvim_buf_get_keymap(bufnr, "n")
    maps = vim.tbl_extend("force", maps, buffer_keymaps)
  end

  for _, map in ipairs(maps) do
    if map.lhs == lhs then
      return map
    end
  end
end

describe("stackmap", function()
  before_each(function()
    require("stackmap")._clear()

    -- Please don't have this mapping when we start.
    pcall(vim.keymap.del, "n", "asdfasdf")
    pcall(vim.keymap.del, "n", "asdf_1")
    pcall(vim.keymap.del, "n", "asdfasdf", { buffer = vim.api.nvim_get_current_buf() })
    pcall(vim.keymap.del, "n", "asdf_1", { buffer = vim.api.nvim_get_current_buf() })
  end)

  it("can be required", function()
    require("stackmap")
  end)

  it("can push a single mapping", function()
    local rhs = "echo 'This is a test'"
    require("stackmap").push("test1", "n", {
      { "asdfasdf", rhs },
    })

    local found = find_map("asdfasdf")
    assert.are.same(rhs, found.rhs)
  end)

  it("can push multiple mappings", function()
    local rhs = "echo 'This is a test'"
    require("stackmap").push("test1", "n", {
      { "asdf_1", rhs .. "1" },
      { "asdf_2", rhs .. "2" },
    })

    local found_1 = find_map("asdf_1")
    assert.are.same(rhs .. "1", found_1.rhs)

    local found_2 = find_map("asdf_2")
    assert.are.same(rhs .. "2", found_2.rhs)
  end)

  it("can delete mappings after pop: no existing", function()
    local rhs = "echo 'This is a test'"
    require("stackmap").push("test1", "n", {
      { "asdfasdf", rhs },
    })

    local found = find_map("asdfasdf")
    assert.are.same(rhs, found.rhs)

    require("stackmap").pop("test1", "n")
    local after_pop = find_map("asdfasdf")
    assert.are.same(nil, after_pop)
  end)

  it("can delete mappings after pop: yes existing", function()
    vim.keymap.set("n", "asdfasdf", "echo 'OG MAPPING'")

    local rhs = "echo 'This is a test'"
    require("stackmap").push("test1", "n", {
      { "asdfasdf", rhs },
    })

    local found = find_map("asdfasdf")
    assert.are.same(rhs, found.rhs)

    require("stackmap").pop("test1", "n")
    local after_pop = find_map("asdfasdf")
    assert.are.same("echo 'OG MAPPING'", after_pop.rhs)
  end)

  it("can restore mapping options", function()
    vim.keymap.set("n", "asdf_1", "echo 'OG MAPPING'", {
      silent = 1,
      desc = "Mapping description",
    })

    local rhs = "echo 'This is a test'"
    require("stackmap").push("test1", "n", {
      { "asdf_1", rhs },
    })
    require("stackmap").pop("test1", "n")

    local after_pop = find_map("asdf_1")
    assert.are.same("Mapping description", after_pop.desc)
    assert.are.same(1, after_pop.silent)
  end)

  it("can restore buffer mappings", function()
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

    local after_pop = find_map("asdfasdf", vim.api.nvim_get_current_buf())
    assert.are.same("echo 'OG MAPPING'", after_pop.rhs)
    assert.are.same("description", after_pop.desc)
    assert.are.same(1, after_pop.silent)
    assert.are.same(bufnr, after_pop.buffer)
  end)

  it("can handle multiple calls: with the same group name", function()
    local rhs = "echo 'OG MAPPING'"
    vim.keymap.set("n", "asdfasdf", rhs)

    local rhs_1 = "echo 'This is a test 1'"
    local rhs_2 = "echo 'This is a test 2'"
    require("stackmap").push("test1", "n", {
      { "asdfasdf", rhs_1 },
    })
    require("stackmap").push("test1", "n", {
      { "asdfasdf", rhs_2 },
    })
    require("stackmap").pop("test1", "n")

    local after_pop = find_map("asdfasdf")
    assert.are.same(rhs, after_pop.rhs)
  end)

  it("can handle multiple calls: with the different group names", function()
    local rhs = "echo 'OG MAPPING'"
    vim.keymap.set("n", "asdfasdf", rhs)

    local rhs_1 = "echo 'This is a test 1'"
    local rhs_2 = "echo 'This is a test 2'"
    require("stackmap").push("test1", "n", {
      { "asdfasdf", rhs_1 },
    })
    require("stackmap").push("test2", "n", {
      { "asdfasdf", rhs_2 },
    })
    require("stackmap").pop("test2", "n")
    require("stackmap").pop("test1", "n")

    local after_pop = find_map("asdfasdf")
    assert.are.same(rhs, after_pop.rhs)
  end)
end)
