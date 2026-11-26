const pkg_id = require("@src/pkg/utils/pkg_id")
const semver_range = require("@src/pkg/utils/semver_range")
const source_info = require("@src/pkg/sources/source_info")

export type RawDepEntry =
	{
		version: string,
		github: string,
		rev: nil,
	}
	| {
		github: string,
		rev: string,
		version: nil,
	}

export type DependencyEntry = {
	global_name: pkg_id.GlobalName,
	version: semver_range.Identity,
	source: source_info.Git,
}

-- names and owners end up in a remote url and in filesystem paths, so no separators or leading dots
const SEGMENT_PATTERN = "^[%w_][%w_%.%-]*$"

--[[
	implicit caret operator
]]
const function version_with_default_caret(text: string): semver_range.Identity
	if semver_range.operators[string.sub(text, 1, 1)] then
		return semver_range.parse(text)
	end

	return semver_range.parse("^" .. text)
end

const m_dependency_parser = {}

function m_dependency_parser.parse_dep(raw_name: string, raw: RawDepEntry): DependencyEntry
	assert(type(raw_name) == "string", "dependency names must be strings")
	assert(type(raw) == "table", `{raw_name}: the dependency must be a table`)

	const global_name = pkg_id.global_name(raw_name)
	assert(
		string.find(global_name, SEGMENT_PATTERN),
		`invalid dependency name "{raw_name}", only letters, digits, "_", "-" and "." are allowed`
	)
	assert(raw.github, "non-github dependencies are unsupported at this time")
	assert(
		type(raw.github) == "string" and string.find(raw.github, SEGMENT_PATTERN),
		`{global_name}: github must be a single owner name`
	)
	assert(raw.version == nil or type(raw.version) == "string", `{global_name}: version must be a string`)
	assert(raw.rev == nil or type(raw.rev) == "string", `{global_name}: rev must be a string`)
	assert(raw.version or raw.rev, `{global_name}: no version or revision`)

	return {
		global_name = global_name,
		version = if raw.version then version_with_default_caret(raw.version) else semver_range.any,

		source = {
			type = "git",
			remote = `https://github.com/{raw.github}/{global_name}.git`,
			rev = raw.rev,
		},
	}
end

return table.freeze(m_dependency_parser)
