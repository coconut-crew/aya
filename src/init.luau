const cli = require("@src/cli")
const configure = require("@src/build/cmds/configure")
const link = require("@src/build/internal_cmds/link")
const path = require("@std/path")
const process = require("@std/process")
const regen = require("@src/build/internal_cmds/regen")
const transform = require("@src/build/internal_cmds/transform")

const args = table.clone(process.args)
table.remove(args, 1)

--[[
	should probably figure something out here eventually,
	this isn't fun
]]
if args[1] == "--internal" then
	if args[2] == "transform" then
		assert(#args >= 5, "usage: --internal transform <src> <dst> <plan>")
		transform(path.parse(args[3]), path.parse(args[4]), path.parse(args[5]))
	elseif args[2] == "link" then
		assert(#args >= 4, "usage: --internal link <input> <output>")
		link(path.parse(args[3]), path.parse(args[4]))
	elseif args[2] == "configure" then
		configure()
	elseif args[2] == "regen" then
		regen()
	else
		error(`unknown internal command {args[2] or "(none)"}`)
	end

	return
end

cli(args)
