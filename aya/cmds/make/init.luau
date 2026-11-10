const anchors = require("@aya/common/anchors")
const fs = require("@std/fs")
const path = require("@std/path")

const make = {}

function make.configure(loc: path.Pathlike)
	anchors.set(loc)
end

function make.build(loc: path.Pathlike) end

function make.regen() end

return table.freeze(make)
