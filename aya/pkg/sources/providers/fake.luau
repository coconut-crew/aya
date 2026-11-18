const create_provider = require("@aya/pkg/sources/create_provider")
const pkg_id = require("@aya/pkg/utils/pkg_id")
const semver = require("@aya/pkg/utils/semver")

export type Registry = { [pkg_id.GlobalName]: { [string]: create_provider.DependencySet } }

const registry: Registry = {}

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

	provider = create_provider(function(sources)
		return {
			get_dependencies_async = function(
				name: pkg_id.GlobalName,
				version: semver.Identity
			): create_provider.DependencySet
				const deps = registry[name][semver.print(version)]

				for dependency_name in deps do
					if sources[dependency_name] then
						continue
					end

					sources[dependency_name] = { type = "fake" }
				end

				return deps
			end,
			get_versions_async = get_versions_async,

			download_async = function() end,
		}
	end),
}

return table.freeze(fake)
