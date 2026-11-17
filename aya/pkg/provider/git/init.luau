const net = require("@std/net")
const path = require("@std/path")
const pkg_id = require("@aya/pkg/utils/pkg_id")
const process = require("@std/process")
const provider_tys = require("@aya/pkg/provider/provider_tys")
const semver = require("@aya/pkg/utils/semver")

export type GitSourceInfo = {
	type: "git",
	remote: string,
}

const manifest_url_template = "https://raw.githubusercontent.com/%*/%*/%*/.aya.toml"

const function remote_download_async(remote: string, commit: string, output: path.Pathlike)
	const res = process.run(
		{ "git", "clone", "--depth=1", `--revision={commit}`, "--", remote, path.format(output) },
		{ stdio = "inherit" }
	)
	assert(res.ok, `process failed with exit code {res.exitcode}:\n{res.stderr}`)
end

const git = {
	remote_parse_lsremote = remote_parse_lsremote,
}

function git.provider(): provider_tys.SourceProvider<GitSourceInfo>
	const provider: provider_tys.SourceProvider<GitSourceInfo> = {} :: never
	const version_cache = {}
	const source_lists: { [pkg_id.GlobalName]: GitSourceInfo } = {}

	function provider.get_versions_async(global_name: pkg_id.GlobalName): { semver.Identity }
		const version_records = remote_get_versions_async(source_lists[global_name].remote)
		for _, entry in version_records do
		end
	end

	function provider.get_dependencies_async(
		global_name: pkg_id.GlobalName,
		version: semver.Identity
	)
	end

	function provider.set_info(global_name: pkg_id.GlobalName, info: GitSourceInfo)
		source_lists[global_name] = info
	end

	function provider.download_async(
		global_name: pkg_id.GlobalName,
		version: semver.Identity,
		at: path.Pathlike
	)
	end

	return provider
end

return git
