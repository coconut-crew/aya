const app_dirs = require("@aya/common/app_dirs")
const cache = require("@aya/pkg/utils/cache")
const canonicalize_remote = require("@aya/pkg/utils/canonicalize_remote")
const crypto = require("@lute/crypto")
const fs = require("@std/fs")
const manifest = require("@aya/manifest")
const path = require("@std/path")
const process = require("@std/process")
const semver = require("@aya/pkg/utils/semver")
const to_hex = require("@aya/common/utils/to_hex")

type VersionRevisionMap = { [string]: string }

const TAG_PATTERN = "^refs/tags/v?([^%^]+)"
const PARSE_CACHE_ENTRY_PATTERN = "%s*([^=\n]-)%s*=%s*([^\n]-)%s*\n"
const REPOS_CACHE_DIR = "git_repos"

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

--[[
	AI generated implementations:
	i hate working with git so much.
]]

-- picks the commit out of `git ls-remote` output for one branch or tag
const function parse_ref_lookup(content: string): string?
	local found: string? = nil
	for _, line in string.split(content, "\n") do
		const revision, ref = table.unpack(string.split(line, "\t"))
		if not (revision and ref) then
			continue
		end

		-- an annotated tag points at a tag object, its peeled entry points at the commit
		if string.sub(ref, -3) == "^{}" then
			return revision
		end

		found = found or revision
	end

	return found
end

const function is_commit_hash(rev: string): boolean
	return #rev == 40 and string.find(rev, "^%x+$") ~= nil
end

const function resolve_rev(remote: string, rev: string): string
	if is_commit_hash(rev) then
		return rev
	end

	const res = process.run({
		"git",
		"ls-remote",
		"--",
		remote,
		`refs/heads/{rev}`,
		`refs/tags/{rev}`,
		`refs/tags/{rev}^\{}`,
	})
	assert(res.ok, `process failed with exit code {res.exitcode}:\n{res.stderr}`)

	const revision = parse_ref_lookup(res.stdout)
	assert(revision, `{remote} has no branch or tag named {rev}, pin a commit with its full hash`)

	return revision
end

--[[
	End AI generated implementations
]]

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

-- fetched through git so the credential helper handles private repos
const function read_manifest_async(
	manifest_cache: cache.Identity,
	remote: string,
	revision: string
): string
	const cached = manifest_cache:get(revision)
	if cached then
		return cached
	end

	const repo =
		path.format(path.join(app_dirs.get("cache"), REPOS_CACHE_DIR, remote_cache_key(remote)))
	if not fs.exists(repo) then
		const init = process.run({ "git", "init", "--bare", "--quiet", "--", repo })
		assert(init.ok, `git failed with exit code {init.exitcode}:\n{init.stderr}`)
	end

	const fetch = process.run({
		"git",
		"-C",
		repo,
		"fetch",
		"--quiet",
		"--depth=1",
		"--filter=blob:none",
		"--",
		remote,
		revision,
	})
	assert(fetch.ok, `fetching {remote} at rev {revision} failed:\n{fetch.stderr}`)

	const file = process.run({
		"git",
		"-C",
		repo,
		"cat-file",
		"blob",
		`{revision}:{manifest.CONFIG_FILE_NAME}`,
	})
	assert(file.ok, `reading manifest from {remote} at {revision} failed:\n{file.stderr}`)

	manifest_cache:set(revision, file.stdout)

	return file.stdout
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

function git_cache.get_manifest_async(
	self: Identity,
	remote: string,
	revision: string
): manifest.Identity
	return manifest.parse(read_manifest_async(self.manifest_cache, remote, revision))
end

table.freeze(git_cache)
return table.freeze({
	new = constructor,

	remote_cache_key = remote_cache_key,
	remote_ls_tags = remote_ls_tags,
	parse_ls_remote = parse_ls_remote,
	parse_ref_lookup = parse_ref_lookup,
	resolve_rev = resolve_rev,
})
