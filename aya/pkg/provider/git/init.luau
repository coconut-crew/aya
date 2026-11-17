const net = require("@std/net")
const path = require("@std/path")
const pkg_id = require("@aya/pkg/pkg_id")
const process = require("@std/process")
const provider_tys = require("@aya/pkg/provider/provider_tys")
const semver = require("@aya/pkg/utils/semver")

export type GitSourceInfo = {
	type: "git",
	remote: string,
}

type GitVersionRecord = {
	revision: string,
	version: semver.Identity,
}

const tag_pattern = "^refs/tags/v?([^%^]+)"
const manifest_url_template = "https://raw.githubusercontent.com/%*/%*/%*/.aya.toml"

const function remote_parse_lsremote(content: string): { GitVersionRecord }
	-- { [version string]: index where versions[index] == version string }
	const version_index: { [string]: number } = {}
	const versions: { GitVersionRecord } = {}

	for _, line in string.split(content, "\n") do
		-- don't know why it's separated by tabs but oh well
		const revision, ref = table.unpack(string.split(line, "\t"))

		-- if (revision, ref) is not true, we are at the end
		if not (revision and ref) then
			break
		end

		const version_string = string.match(ref, tag_pattern)
		if not version_string then
			continue
		end

		const ok, version = pcall(semver.parse, version_string)
		if not ok then
			continue
		end

		const existing_record = version_index[version_string]
		if existing_record then
			if string.sub(ref, -3) == "^{}" then
				versions[existing_record].revision = revision
			end

			continue
		end

		const version_record: GitVersionRecord = {
			version = version,
			revision = revision,
		}

		table.insert(versions, version_record)
		version_index[version_string] = #versions
	end

	-- luau issue: this instantiation shouldn't be necessary
	table.sort<<GitVersionRecord>>(versions, function(left, right)
		return semver.newer(left.version, right.version)
	end)

	return versions
end

const function remote_get_versions_async(remote: string): { GitVersionRecord }
	const res =
		process.system(`git -c versionsort.suffix=- ls-remote --tags --sort=v:refname {remote}`)
	assert(res.ok, `process failed with exit code {res.exitcode}:\n{res.stderr}`)

	return remote_parse_lsremote(res.stdout)
end

const function remote_download_async(remote: string, commit: string, output: path.Pathlike)
	const res =
		process.system(`git clone --depth=1 --revision={commit} {remote} {path.format(output)}`, {
			stdio = "inherit",
		})
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
