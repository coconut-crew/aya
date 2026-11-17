const cache = require("@aya/pkg/utils/cache")
const canonicalize_remote = require("@aya/pkg/utils/canonicalize_remote")
const crypto = require("@lute/crypto")
const process = require("@std/process")
const semver = require("@aya/pkg/utils/semver")
const to_hex = require("@aya/common/utils/to_hex")

type VersionRevisionMap = { [string]: string }

const TAG_PATTERN = "^refs/tags/v?([^%^]+)"
const PARSE_CACHE_ENTRY_PATTERN = "%s*([^=\n]-)%s*=%s*([^\n]-)%s*\n"

const function parse_ls_remote(content: string): VersionRevisionMap
	const versions: VersionRevisionMap = {}

	for _, line in string.split(content, "\n") do
		const revision, ref = table.unpack(string.split(line, "\t"))

		-- if (revision, ref) is not true, we are at the end
		if not (revision and ref) then
			break
		end

		const version_string = string.match(ref, TAG_PATTERN)
		if not version_string then
			continue
		end

		const ok, res = pcall(semver.parse, version_string)
		if not ok then
			continue
		end

		const formatted = semver.print(res)

		-- annotated tag support
		if string.sub(ref, -3) == "^{}" or not versions[formatted] then
			versions[formatted] = revision
		end
	end

	return versions
end

const function remote_ls_tags(remote: string): VersionRevisionMap
	const res = process.run({ "git", "ls-remote", "--tags", "--", remote })
	assert(res.ok, `process failed with exit code {res.exitcode}:\n{res.stderr}`)

	return parse_ls_remote(res.stdout)
end

const function remote_cache_key(remote: string): string
	const out = crypto.digest(crypto.hash.md5, canonicalize_remote(remote))
	const as_str = to_hex.string(out)
	const key = string.sub(as_str, 1, math.min(16, #as_str))

	return key
end

-- { [version]: hash }
const function cache_entry_serialize(ls_results: VersionRevisionMap): string
	const lines: { string } = {}

	for tag, hash in ls_results do
		table.insert(lines, tag .. "=" .. hash)
	end

	return table.concat(lines, "\n") .. "\n"
end

const function cache_entry_deserialize(contents: string): VersionRevisionMap
	const working_tbl: VersionRevisionMap = {}

	for version_str, revision in string.gmatch(contents, PARSE_CACHE_ENTRY_PATTERN) do
		working_tbl[version_str] = revision
	end

	return working_tbl
end

const git_cache = {}
git_cache.__index = git_cache
type Identity = setmetatable<{
	int_cache: cache.Identity,

	in_memory: { [string]: VersionRevisionMap },
}, typeof(git_cache)>

const function constructor(): Identity
	const self = setmetatable({
		int_cache = cache.new_async("git_meta"),
		in_memory = {},
	}, git_cache)

	return self
end

function git_cache.update_tag_rev_map_async(self: Identity, remote: string)
	const revisions: VersionRevisionMap = remote_ls_tags(remote)

	self.in_memory[remote] = revisions
	self.int_cache:set(remote_cache_key(remote), cache_entry_serialize(revisions))
end

function git_cache.get_revision_async(
	self: Identity,
	remote: string,
	version: semver.Identity
): string
	const version_string = semver.print(version)

	const remote_memory_entry = self.in_memory[remote] and self.in_memory[remote][version_string]
	if remote_memory_entry then
		return remote_memory_entry
	end

	if not self.in_memory[remote] then
		const cache_entry = self.int_cache:get(remote_cache_key(remote))
		self.in_memory[remote] = if cache_entry then cache_entry_deserialize(cache_entry) else {}
	end

	if not self.in_memory[remote][version_string] then
		self:update_tag_rev_map_async(remote)
	end

	const revision = self.in_memory[remote][version_string]
	assert(revision, `{remote} does not have version {version_string}`)

	return revision
end

function git_cache.get_versions_async(self: Identity, remote: string) end

function git_cache.get_dependencies_async(self: Identity, remote: string) end

table.freeze(git_cache)
return {
	new = constructor,

	remote_cache_key = remote_cache_key,
	remote_ls_tags = remote_ls_tags,
	parse_ls_remote = parse_ls_remote,
}
