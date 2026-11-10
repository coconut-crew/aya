const anchors = require("@aya/common/anchors")
const fs = require("@std/fs")
const luninjau = require("@pkgs/luninjau")
const path = require("@std/path")
const static_ninja_content = require("@aya/buildsys/static_ninja_content")

const buildsys = {}

function buildsys.bproc_regen()
	fs.createDirectory(anchors.build(), {
		makeParents = true,
	})

	static_ninja_content.write_rules()
end

function buildsys.bproc_link(crate_loc: path.Pathlike)
	fs.createDirectory(path.join(anchors.build(), "links"), {
		makeParents = true,
	})
end

function buildsys.bproc_build(src: path.Pathlike, dst: path.Pathlike)
	-- temp
	fs.copy(src, dst)
end

function buildsys.bproc_discover_deps() end

return table.freeze(buildsys)
