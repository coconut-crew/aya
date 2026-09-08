const subcommand_ty = require("@common/subcommand_ty")
const process = require("@std/process")
const cli = require("@vendor/cli")

const install: subcommand_ty.Subcommand = {
	parser = function()
		const parser = cli.parser()

		return parser
	end,

	run = function() end,
}

return install
