const anchors = require("@aya/common/anchors")
const fs = require("@std/fs")
const luninjau = require("@pkgs/luninjau")
const path = require("@std/path")

const RULES_NINJA_FILE = "rules.ninja"
const NINJA_MIN_VERSION = "1.13.2"

const static_ninja_content = {}

function static_ninja_content.write_rules()
	fs.writeStringToFile(
		path.join(anchors.build(), RULES_NINJA_FILE),
		luninjau.print_file({
			version = NINJA_MIN_VERSION,
			stmts = {
				{
					stat = "rule",

					name = "regen",
					variables = {
						command = "aya bproc regen",
					},
				},

				{
					stat = "rule",

					name = "build",
					variables = {
						command = "aya bproc build",
					},
				},

				{
					stat = "rule",

					name = "scan",
					variables = {
						command = "aya bproc scan",
					},
				},

				{
					stat = "rule",

					name = "link",
					variables = {
						command = "aya bproc link",
					},
				},
			},
		})
	)
end

return table.freeze(static_ninja_content)
