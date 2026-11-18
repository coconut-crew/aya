const path = require("@std/path")
const pkg_id = require("@aya/pkg/utils/pkg_id")
const semver = require("@aya/pkg/utils/semver")
const semver_range = require("@aya/pkg/utils/semver_range")
const source_info = require("@aya/pkg/sources/source_info")

export type DependencySet = { [pkg_id.GlobalName]: semver_range.Identity }

export type Impl<T> = {
	download_async: (
		name: pkg_id.GlobalName,
		version: semver.Identity,
		at: path.Pathlike
	) -> (),

	get_dependencies_async: (
		name: pkg_id.GlobalName,
		version: semver.Identity
	) -> DependencySet,

	get_versions_async: (name: pkg_id.GlobalName) -> { semver.Identity },
}

export type Identity<T> = {
	download_async: (name: pkg_id.GlobalName, version: semver.Identity, at: path.Pathlike) -> (),

	get_dependencies_async: (name: pkg_id.GlobalName, version: semver.Identity) -> DependencySet,
	get_versions_async: (name: pkg_id.GlobalName) -> { semver.Identity },
}

const function create_provider<T>(impl_constructor: (
	sources: { [pkg_id.GlobalName]: source_info.Identity }
) -> Impl<T>): (
	sources: { [pkg_id.GlobalName]: source_info.Identity }
) -> Identity<T>
	return impl_constructor
end

return create_provider
