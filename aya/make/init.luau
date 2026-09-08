const subcommand_ty = require("@common/subcommand_ty")

const make: subcommand_ty.Subcommand = {
	parser = function(parser)
		parser:add("path", "positional", {})
	end,

	run = function(parser)
		print(parser:get("path"), parser:get("subcommand"))
	end,
}

return make
