const anchors = require("@aya/common/anchors")
const description = require("@aya/description")
const generate_linker_file = require("@aya/common/generate_linker_file")
const luninjau = require("@pkgs/luninjau")
const path = require("@std/path")
const process = require("@std/process")

const crate = {}

function crate.build_link_stmts(crate: description.CrateLib)
	error("unimplemented")
end

function crate.build_binary_stmts(crate: description.CrateBin): luninjau.NinjaStatBuild
	return {
		stat = "build",
		rule = "compile",

		outputs = {
			luninjau.escape(path.format(path.join(anchors.build(), "bin", crate.alias))),
		},

		dependencies = {
			luninjau.escape(path.format(crate.main)),
		},

		variables = {},
	}
end

return table.freeze(crate)
