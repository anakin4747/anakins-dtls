local busted = require("busted")
local assert = require("luassert")
local describe = busted.describe
local it = busted.it

package.path = "./lua/?.lua;" .. package.path
local json = require("json")

describe("json.encode()", function()
    it("encodes an empty table as an empty object by default", function()
        assert.are.equal("{}", json.encode({}))
    end)

    it("encodes a table tagged with json.array() as an empty array", function()
        assert.are.equal("[]", json.encode(json.array({})))
    end)

    it("still encodes non-empty tables with array keys as arrays", function()
        assert.are.equal("[1,2,3]", json.encode({ 1, 2, 3 }))
    end)

    it("still encodes non-empty tables with string keys as objects", function()
        assert.are.equal('{"a":1}', json.encode({ a = 1 }))
    end)
end)
