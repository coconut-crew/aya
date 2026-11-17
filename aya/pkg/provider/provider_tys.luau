const path = require("@std/path")
const pkg_id = require("@aya/pkg/pkg_id")
const semver = require("@aya/pkg/utils/semver")
const semver_range = require("@aya/pkg/utils/semver_range")

export type SourceProvider<T> = {
	get_versions_async: (global_name: pkg_id.GlobalName) -> { semver.Identity },
	get_dependencies_async: (
		global_name: pkg_id.GlobalName,
		version: semver.Identity
	) -> { [pkg_id.GlobalName]: semver_range.Identity },
	download_async: (
		global_name: pkg_id.GlobalName,
		version: semver.Identity,
		at: path.Pathlike
	) -> (),

	set_info: (global_name: pkg_id.GlobalName, info: T) -> (),
}

export type Registry = {
	-- global name: { [version]: { dependency list } }
	[pkg_id.GlobalName]: { [string]: { [pkg_id.GlobalName]: semver_range.Identity } },
}

return nil
