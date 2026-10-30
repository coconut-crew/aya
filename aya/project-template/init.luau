const anchors = require("@aya-common/anchors")
const cli = require("@vendor/cli")
const fs = require("@std/fs")
const path = require("@std/path")
const path_to_file_name = require("@aya-common/utils/path_to_file_name")
const process = require("@std/process")
const subcommand_ty = require("@aya-common/subcommand_ty")

const compose: subcommand_ty.Subcommand = {
	run = function(args)
		const parser = cli.parser()

		parser:add("editors", "option", {
			required = false,
		})

		parser:add("type", "positional", {
			required = false,
		})

		parser:parse(args)

		const editor_list = parser:get("editors")
	end,
}

return compose
