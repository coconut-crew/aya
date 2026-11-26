const cli = require("@src/cli")
const link = require("@src/build/internal_cmds/link")
const path = require("@std/path")
const process = require("@std/process")
const regen = require("@src/build/internal_cmds/regen")
const transform = require("@src/build/internal_cmds/transform")

const args = table.clone(process.args)
table.remove(args, 1)

if args[1] == "--internal" then
	if args[2] == "transform" then
		transform(path.parse(args[3]), path.parse(args[4]), path.parse(args[5]))
	elseif args[2] == "link" then
		link()
	elseif args[2] == "regen" then
		regen()
	end
end

cli(args)
