local adapter = require("neotest-jest")({ jestCommand = "jest" })
local async = require("nio").tests
local stub = require("luassert.stub")
local util = require("neotest-jest.util")

describe("adapter.is_test_file", function()
  async.it("matches jest test files", function()
    assert.True(adapter.is_test_file("./spec/basic.test.ts"))
  end)

  async.it("does not match plain js/ts files", function()
    assert.False(adapter.is_test_file("./index.js"))
    assert.False(adapter.is_test_file("./index.ts"))
  end)

  it("gets default test extensions", function()
    local intermediate_extensions, extensions = util.default_test_extensions()

    assert.same(
      intermediate_extensions,
      { "spec", "e2e%-spec", "test", "unit", "regression", "integration" }
    )
    assert.same(extensions, { "js", "jsx", "coffee", "ts", "tsx" })
  end)

  async.it("matches test files with default test patterns", function()
    stub(require("neotest.lib").files, "match_root_pattern", function()
      return function(path)
        return path
      end
    end)

    stub(require("neotest.lib").files, "read", function()
      return [[
{
  "name": "spec",
  "version": "1.0.0",
  "description": "neotest-jest spec",
  "main": "index.js",
  "license": "MIT",
  "dependencies": {
    "jest": "^28.1.2",
    "ts-node": "^10.8.2",
    "typescript": "^4.7.4"
  },
  "devDependencies": {
    "@types/jest": "^28.1.4",
    "@types/node": "^18.0.3"
  }
}]]
    end)

    local intermediate_extensions, extensions = util.default_test_extensions()

    for _, extension1 in ipairs(intermediate_extensions) do
      for _, extension2 in ipairs(extensions) do
        local stripped_path, _ = ("./spec/basic." .. extension1 .. "." .. extension2):gsub(
          "%%%-",
          "%-"
        )

        assert.True(adapter.is_test_file(stripped_path))
      end
    end

    require("neotest.lib").files.match_root_pattern:revert()
    require("neotest.lib").files.read:revert()
  end)

  async.it("matches test files with configurable test patterns", function()
    local intermediate_extensions = { "spec", "lollipop" }
    local extensions = { "js", "ts" }
    local is_test_file =
      util.create_test_file_extensions_matcher(intermediate_extensions, extensions)

    for _, extension1 in ipairs(intermediate_extensions) do
      for _, extension2 in ipairs(extensions) do
        assert.True(is_test_file("./spec/basic." .. extension1 .. "." .. extension2))
      end
    end

    -- Does not match anymore with custom extensions
    assert.False(is_test_file("./spec/basic.test.ts"))
  end)
end)
