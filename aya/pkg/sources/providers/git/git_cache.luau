const cache = require("@aya/pkg/utils/cache")
const canonicalize_remote = require("@aya/pkg/utils/canonicalize_remote")
const crypto = require("@lute/crypto")
const manifest = require("@aya/manifest")
const net = require("@std/net")
const pkg_id = require("@aya/pkg/utils/pkg_id")
const process = require("@std/process")
const semver = require("@aya/pkg/utils/semver")
const semver_range = require("@aya/pkg/utils/semver_range")
const source_info = require("@aya/pkg/sources/source_info")
const to_hex = require("@aya/common/utils/to_hex")

type VersionRevisionMap = { [string]: string }

const TAG_PATTERN = "^refs/tags/v?([^%^]+)"
const PARSE_CACHE_ENTRY_PATTERN = "%s*([^=\n]-)%s*=%s*([^\n]-)%s*\n"
const MANIFEST_URL_TEMPLATE = "https://raw.githubusercontent.com/%*/%*/%*/.aya.toml"
const GITHUB_PREFIX = "https://github.com/"

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

const function github_manifest_url(remote: string, revision: string): string
	const canonical = canonicalize_remote(remote)

	const owner, repo = table.unpack(string.split(string.sub(canonical, #GITHUB_PREFIX + 1), "/"))
	assert(owner and repo, `what how`)

	return string.format(MANIFEST_URL_TEMPLATE, owner, repo, revision)
end

const function fetch_manifest_async(url: string): string
	const res = net.request(url)
	assert(res.ok, `failed to fetch manifest at {url} with status {res.status}`)

	return res.body
end

const function read_manifest_async(
	manifest_cache: cache.Identity,
	remote: string,
	revision: string
): string
	const cached = manifest_cache:get(revision)
	if cached then
		return cached
	end

	-- TODO: when we do non-github hosts, remove this
	const contents = fetch_manifest_async(github_manifest_url(remote, revision))
	manifest_cache:set(revision, contents)

	return contents
end

const git_cache = {}
git_cache.__index = git_cache
export type Identity = setmetatable<{
	int_cache: cache.Identity,
	manifest_cache: cache.Identity,

	in_memory: { [string]: VersionRevisionMap },
}, typeof(git_cache)>

const function constructor(): Identity
	const self = setmetatable({
		int_cache = cache.new_async("git_meta"),
		manifest_cache = cache.new_async("git_manifests"),

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

function git_cache.get_versions_async(self: Identity, remote: string): { semver.Identity }
	if not self.in_memory[remote] then
		self:update_tag_rev_map_async(remote)
	end

	const versions: { semver.Identity } = {}
	for version_string in self.in_memory[remote] do
		table.insert(versions, semver.parse(version_string))
	end

	table.sort(versions, semver.newer)

	return versions
end

function git_cache.get_dependencies_async(
	self: Identity,
	remote: string,
	version: semver.Identity,
	sources: { [pkg_id.GlobalName]: source_info.Identity }
): { [pkg_id.GlobalName]: semver_range.Identity }
	const revision = self:get_revision_async(remote, version)
	const manifest_contents = read_manifest_async(self.manifest_cache, remote, revision)
	const parsed_manifest = manifest.parse(manifest_contents)

	const dependencies: { [pkg_id.GlobalName]: semver_range.Identity } = {}

	for global_name, entry in parsed_manifest.dependencies do
		dependencies[global_name] = entry.version
	end

	return dependencies
end

table.freeze(git_cache)
return table.freeze({
	new = constructor,

	remote_cache_key = remote_cache_key,
	remote_ls_tags = remote_ls_tags,
	parse_ls_remote = parse_ls_remote,
})
