const anchors = require("@aya/common/anchors")
const fs = require("@std/fs")
const luninjau = require("@pkgs/luninjau")
const path = require("@std/path")

const buildsys = {}

function buildsys.cmd_regen()
	fs.createDirectory(anchors.build(), {
		makeParents = true,
	})

	fs.writeStringToFile(
		path.join(anchors.build(), ""),
		luninjau.print_file({
			version = "",
			stmts = {
				{
					stat = "rule",

					name = "regen",
					variables = {
						command = "aya bproc regen $in $out",
					},
				},

				{
					stat = "rule",

					name = "build",
					variables = {
						command = "aya bproc build $in $out",
					},
				},

				{
					stat = "rule",

					name = "scan",
					variables = {
						command = "aya bproc scan $in $out",
					},
				},

				{
					stat = "rule",

					name = "link",
					variables = {
						command = "aya bproc link $in $out",
					},
				},

				{
					stat = "rule",

					name = "compile",
					variables = {
						command = "lute compile $in $out",
					},
				},
			},
		})
	)
end

function buildsys.cmd_link(crate_loc: path.Pathlike)
	fs.createDirectory(path.join(anchors.build(), "links"), {
		makeParents = true,
	})
end

function buildsys.cmd_build(src: path.Pathlike, dst: path.Pathlike)
	-- temp
	fs.copy(src, dst)
end

function buildsys.cmd_discover_deps() end

function buildsys.build() end

function buildsys.configure() end

return table.freeze(buildsys)
