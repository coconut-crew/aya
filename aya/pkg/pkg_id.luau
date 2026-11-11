const anchors = require("@aya/common/anchors")
const path = require("@std/path")
const path_to_file_name = require("@aya/common/utils/path_to_file_name")
const pkg_types = require("@aya/pkg/pkg_types")

export type Identity = string

const pkg_id = {}

function pkg_id.git(install: pkg_types.GitInstall): Identity
	-- TODO clean up ternary logic
	return `git-{install.branch}-{install.revision}` .. if install.subpath then path.basename(install.subpath) or "" else ""
end

function pkg_id.path(install: pkg_types.PathInstall): Identity
	return `path-{path_to_file_name(anchors.workspace(), install.src_path :: path.Path)}`
end

return table.freeze(pkg_id)
