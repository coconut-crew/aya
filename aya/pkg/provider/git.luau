const path = require("@std/path")
const process = require("@std/process")
const semver = require("@aya/pkg/utils/semver")

const tag_pattern = "^refs/tags/v?([^%^]+)"

export type GitVersionRecord = {
	version: semver.Identity,
	revision: string,
}

const git = {}

function git.get_versions_async(remote: string): { GitVersionRecord }
	const res =
		process.system(`git -c versionsort.suffix=- ls-remote --tags --sort=v:refname {remote}`)
	assert(res.ok, `process failed with exit code {res.exitcode}:\n{res.stderr}`)

	-- { [version string]: index where versions[index] == version string }
	const version_index: { [string]: number } = {}
	const versions: { GitVersionRecord } = {}

	for _, line in string.split(res.stdout, "\n") do
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

function git.download_async(remote: string, commit: string, output: path.Pathlike)
	const res =
		process.system(`clone --depth=1 --revision={commit} {remote} {path.format(output)}`, {
			stdio = "inherit",
		})
	assert(res.ok, `process failed with exit code {res.exitcode}:\n{res.stderr}`)
end

return git
