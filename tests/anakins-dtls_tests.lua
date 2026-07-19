local busted = require("busted")
local assert = require("luassert")
local describe = busted.describe
local it = busted.it

describe("anakins-dtls", function()
    it("prints hello world", function()
        local output = io.popen("lua ./lua/anakins-dtls.lua"):read("*a")
        assert.are.equal("hello world\n", output)
    end)
end)
