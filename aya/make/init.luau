const anchors = require("@common/anchors")
const subcommand_ty = require("@common/subcommand_ty")
const path = require("@std/path")
const cli = require("@vendor/cli")

const make: subcommand_ty.Subcommand = {
	run = function(args)
		const parser = cli.parser()

		parser:add("build_kind", "positional", {})
		parser:add("entry_point", "positional", {})

		parser:parse(args)

		const build_kind = parser:get("build_kind")
		if not build_kind then
			print(parser:help())
			return
		end

		const entry_point = parser:get("entry_point")
		if not entry_point then
			print(parser:help())
			return
		end

		const entry_path = path.parse(entry_point)

		if build_kind == "configure" then
			anchors.set(entry_path)
		elseif build_kind == "build" then
			anchors.set(entry_path)
		else
			print(`build kind must be either build or configure`)
		end
	end,
}

return make
