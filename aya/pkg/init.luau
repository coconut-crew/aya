const subcommand_ty = require("@common/subcommand_ty")
const installation = require("@self/installation")
const manifest = require("@self/manifest")
const path = require("@std/path")
const cli = require("@vendor/cli")

const pkg: subcommand_ty.Subcommand = {
	parser = function() end,

	run = function() end,
}

return pkg
