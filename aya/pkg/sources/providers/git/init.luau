const create_provider = require("@aya/pkg/sources/create_provider")
const git_cache = require("@self/git_cache")
const git_download = require("@self/git_download")
const path = require("@std/path")
const pkg_id = require("@aya/pkg/utils/pkg_id")
const semver = require("@aya/pkg/utils/semver")
const source_info = require("@aya/pkg/sources/source_info")

return create_provider(function(sources): create_provider.Impl<source_info.Git>
	const cache = git_cache.new()

	return {
		download_async = function(
			name: pkg_id.GlobalName,
			version: semver.Identity,
			at: path.Pathlike
		): ()
			const src = sources[name]
			assert(src.type == "git")

			git_download.download(src.remote, cache:get_revision_async(src.remote, version), at)
		end,

		get_dependencies_async = function(
			name: pkg_id.GlobalName,
			version: semver.Identity
		): create_provider.DependencySet
			const src = sources[name]
			assert(src.type == "git")

			const dependencies: create_provider.DependencySet = {}
			for dependency_name, entry in cache:get_dependencies_async(src.remote, version) do
				dependencies[dependency_name] = entry.version

				if not sources[dependency_name] then
					sources[dependency_name] = entry.source
				end
			end

			return dependencies
		end,

		get_versions_async = function(name): { semver.Identity }
			const src = sources[name]
			assert(src.type == "git")

			return (cache:get_versions_async(src.remote))
		end,
	}
end)
