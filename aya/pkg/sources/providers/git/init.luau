const create_provider = require("@aya/pkg/sources/create_provider")
const git_cache = require("@self/git_cache")
const git_download = require("@self/git_download")
const path = require("@std/path")
const pkg_id = require("@aya/pkg/utils/pkg_id")
const semver = require("@aya/pkg/utils/semver")
const source_info = require("@aya/pkg/sources/source_info")

const function git(): create_provider.Identity<source_info.Git>
	const cache = git_cache.new()

	return create_provider({
		download_async = function(
			src: source_info.Git,
			_: pkg_id.GlobalName,
			version: semver.Identity,
			at: path.Pathlike
		)
			git_download.download(src.remote, cache:get_revision_async(src.remote, version), at)
		end,

		get_dependencies_async = function(
			src: source_info.Git,
			_: pkg_id.GlobalName,
			version: semver.Identity
		): create_provider.Dependencies
			return cache:get_dependencies_async(src.remote, version)
		end,

		get_versions_async = function(src: source_info.Git): { semver.Identity }
			return cache:get_versions_async(src.remote)
		end,
	})
end

return git
