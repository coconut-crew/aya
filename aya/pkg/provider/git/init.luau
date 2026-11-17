const git_cache = require("@self/git_cache")
const git_download = require("@self/git_download")
const path = require("@std/path")
const pkg_id = require("@aya/pkg/utils/pkg_id")
const provider_tys = require("@aya/pkg/provider/provider_tys")
const semver = require("@aya/pkg/utils/semver")
const semver_range = require("@aya/pkg/utils/semver_range")

const git = {}

function git.provider(): provider_tys.SourceProvider<provider_tys.GitSourceInfo>
	const provider: provider_tys.SourceProvider<provider_tys.GitSourceInfo> = {} :: never
	const remotes: { [pkg_id.GlobalName]: string } = {}
	const cache = git_cache.new()

	const function remote_of(global_name: pkg_id.GlobalName): string
		const remote = remotes[global_name]
		assert(remote, `no git source was set for {global_name}`)

		return remote
	end

	function provider.get_versions_async(global_name: pkg_id.GlobalName): { semver.Identity }
		return cache:get_versions_async(remote_of(global_name))
	end

	function provider.get_dependencies_async(
		global_name: pkg_id.GlobalName,
		version: semver.Identity
	): { [pkg_id.GlobalName]: semver_range.Identity }
		return cache:get_dependencies_async(remote_of(global_name), version)
	end

	function provider.set_info(global_name: pkg_id.GlobalName, info: provider_tys.GitSourceInfo)
		remotes[global_name] = info.remote
	end

	function provider.download_async(
		global_name: pkg_id.GlobalName,
		version: semver.Identity,
		at: path.Pathlike
	)
		const remote = remote_of(global_name)
		git_download.download(remote, cache:get_revision_async(remote, version), at)
	end

	return provider
end

return table.freeze(git)
