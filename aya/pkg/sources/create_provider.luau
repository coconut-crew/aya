const path = require("@std/path")
const pkg_id = require("@aya/pkg/utils/pkg_id")
const semver = require("@aya/pkg/utils/semver")
const semver_range = require("@aya/pkg/utils/semver_range")

export type Dependencies = { [pkg_id.GlobalName]: semver_range.Identity }

export type Impl<T> = {
	download_async: (
		src: T,
		name: pkg_id.GlobalName,
		version: semver.Identity,
		at: path.Pathlike
	) -> (),

	get_dependencies_async: (
		src: T,
		name: pkg_id.GlobalName,
		version: semver.Identity
	) -> Dependencies,
	get_versions_async: (src: T, name: pkg_id.GlobalName) -> { semver.Identity },
}

export type Identity<T> = {
	download_async: (name: pkg_id.GlobalName, version: semver.Identity, at: path.Pathlike) -> (),

	get_dependencies_async: (name: pkg_id.GlobalName, version: semver.Identity) -> Dependencies,
	get_versions_async: (name: pkg_id.GlobalName) -> { semver.Identity },

	on_source_added: (name: pkg_id.GlobalName, src: T) -> (),
}

const function create_provider<T>(impl: Impl<T>): Identity<T>
	const sources: { [pkg_id.GlobalName]: T } = {}
	const dispatch_table: Identity<T> = {} :: never

	const function source_of(name: pkg_id.GlobalName): T
		const src = sources[name]
		assert(src ~= nil, `no source was added for {name}`)

		return src
	end

	function dispatch_table.download_async(
		name: pkg_id.GlobalName,
		version: semver.Identity,
		at: path.Pathlike
	)
		impl.download_async(source_of(name), name, version, at)
	end

	function dispatch_table.get_dependencies_async(
		name: pkg_id.GlobalName,
		version: semver.Identity
	): Dependencies
		return impl.get_dependencies_async(source_of(name), name, version)
	end

	function dispatch_table.get_versions_async(name: pkg_id.GlobalName): { semver.Identity }
		return impl.get_versions_async(source_of(name), name)
	end

	function dispatch_table.on_source_added(name: pkg_id.GlobalName, src: T)
		sources[name] = src
	end

	return dispatch_table
end

return create_provider
