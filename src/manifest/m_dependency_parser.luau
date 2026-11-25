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
	const global_name = pkg_id.global_name(raw_name)
	assert(raw.github, "non-github dependencies are unsupported at this time")
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
