const subcommand_ty = require("@aya-common/subcommand_ty")
const cli = require("@vendor/cli")

const test: subcommand_ty.Subcommand = {
	parser = function()
		const parser = cli.parser()

		return parser
	end,

	run = function() end,
}

return test
