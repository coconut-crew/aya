const create_provider = require("@aya/pkg/sources/create_provider")
const pkg_id = require("@aya/pkg/utils/pkg_id")
const semver = require("@aya/pkg/utils/semver")
const source_info = require("@aya/pkg/sources/source_info")

export type Registry = { [pkg_id.GlobalName]: { [string]: create_provider.DependencySet } }

const registry: Registry = {}

const function get_dependencies_async(
	name: pkg_id.GlobalName,
	version: semver.Identity
): create_provider.DependencySet
	const version_string = semver.print(version)
	const dependencies = registry[name][version_string]
	assert(dependencies, `{name} does not have version {version_string}`)

	return dependencies
end

const function get_versions_async(name: pkg_id.GlobalName): { semver.Identity }
	const result: { semver.Identity } = {}
	for version_string in registry[name] do
		table.insert(result, semver.parse(version_string))
	end

	table.sort(result, semver.newer)

	return result
end

const fake = {
	registry = registry,

	provider = create_provider(function()
		return {
			get_dependencies_async = get_dependencies_async,
			get_versions_async = get_versions_async,

			download_async = function() end,
		}
	end),
}

return table.freeze(fake)
