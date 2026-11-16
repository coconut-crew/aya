const semver = require("@aya/pkg/utils/semver")

export type SourceId = string
export type SourceKind = "git"

-- Since names are globally namespaced, a package's name is unique to that package.
-- Package names are also case insensitive.
export type GlobalName = string

-- GlobalName + Version
export type Identifier = string

const SLASH = string.byte("/")

--[[
	AI-generated implementation of remote canonicalization
	
	Not optimal but not something I'm spending time on right now
]]
const function canonicalize_remote(remote: string): string
	const scheme_end = string.find(remote, "://", 1, true)
	assert(scheme_end, `remote {remote} is not a url`)

	const scheme = string.lower(string.sub(remote, 1, scheme_end - 1))
	const rest = string.sub(remote, scheme_end + 3)
	const path_start = string.find(rest, "/", 1, true) or #rest + 1
	const authority = string.sub(rest, 1, path_start - 1)
	local url_path = string.sub(rest, path_start)

	-- userinfo is case sensitive, the host isn't
	const host_start = (string.find(authority, "@", 1, true) or 0) + 1
	const userinfo = string.sub(authority, 1, host_start - 1)
	const host = string.lower(string.sub(authority, host_start))

	while string.byte(url_path, -1) == SLASH do
		url_path = string.sub(url_path, 1, -2)
	end

	if string.sub(url_path, -4) == ".git" then
		url_path = string.sub(url_path, 1, -5)
	end

	-- github paths are case insensitive and every protocol reaches the same repository
	if host == "github.com" then
		return `https://github.com{string.lower(url_path)}`
	end

	return `{scheme}://{userinfo}{host}{url_path}`
end

const pkg_id = {}

-- we might want to do something interesting with this later
-- for now its just making things case insensitive
function pkg_id.global_name(name: string): GlobalName
	return string.lower(name)
end

function pkg_id.identifier(name: string, version: semver.Identity): Identifier
	return `{pkg_id.global_name(name)}@{semver.print(version)}`
end

function pkg_id.git_source(name: string, version: semver.Identity, remote: string): SourceId
	return `git+{name}+version:{semver.print(version)}+{canonicalize_remote(remote)}`
end

function pkg_id.source_kind(source_id: SourceId): SourceKind
	if string.sub(source_id, 1, 3) == "git" then
		return "git"
	else
		error(`invalid id {source_id}`)
	end
end

return table.freeze(pkg_id)
