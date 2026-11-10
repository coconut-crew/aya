const anchors = require("@aya/common/anchors")
const fs = require("@std/fs")
const luninjau = require("@pkgs/luninjau")
const path = require("@std/path")

const buildsys = {}

function buildsys.btask_regen()
	fs.createDirectory(anchors.build(), {
		makeParents = true,
	})
end

function buildsys.btask_link(crate_loc: path.Pathlike)
	fs.createDirectory(path.join(anchors.build(), "links"), {
		makeParents = true,
	})
end

function buildsys.btask_build(src: path.Pathlike, dst: path.Pathlike)
	-- temp
	fs.copy(src, dst)
end

function buildsys.btask_discover_deps() end

return table.freeze(buildsys)
