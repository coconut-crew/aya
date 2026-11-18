const fs = require("@std/fs")
const log = require("@aya/common/log")
const path = require("@std/path")
const pkg_id = require("@aya/pkg/utils/pkg_id")
const semver = require("@aya/pkg/utils/semver")
const semver_range = require("@aya/pkg/utils/semver_range")
const source_info = require("@aya/pkg/sources/source_info")
const toml = require("@vendor/toml")

export type DependencyEntry = {
	global_name: pkg_id.GlobalName,
	version: semver_range.Identity,
	source: source_info.Git,
}

type RawDepEntry =
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

type RawTableRepresentation = {
	package: { version: string? }?,
	dependencies: {
		[string]: RawDepEntry,
	},
}

export type Identity = {
	version: semver.Identity,

	dependencies: { [pkg_id.GlobalName]: DependencyEntry },
}

const CONFIG_FILE_NAME = ".aya.toml"

--[[
	we want implicit ^
]]
const function version_with_default_caret(text: string): semver_range.Identity
	if semver_range.operators[string.sub(text, 1, 1)] then
		return semver_range.parse(text)
	end

	return semver_range.parse("^" .. text)
end

const manifest = {}

function manifest.parse_raw_dependency(raw_name: string, raw: RawDepEntry): DependencyEntry
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

function manifest.parse(str_content: string): Identity
	log.trace(`\tparsing toml`)

	const raw_table_representation = toml.deserialize(str_content) :: RawTableRepresentation

	log.trace("got toml, converting into internal format")

	const raw_package = raw_table_representation.package
	const raw_version = raw_package and raw_package.version

	const manifest_contents: Identity = {
		version = if raw_version then semver.parse(raw_version) else semver.parse("0.0.0"),
		dependencies = {},
	}

	const raw_dependencies = raw_table_representation.dependencies
	if raw_dependencies ~= nil then
		assert(type(raw_dependencies) == "table", "the dependencies entry must be a table")

		for dependency, data in raw_dependencies do
			const parsed = manifest.parse_raw_dependency(dependency, data)

			manifest_contents.dependencies[pkg_id.global_name(dependency)] = parsed

			log.trace(
				`\tparsed dep [{dependency}]: v{semver_range.print(parsed.version)}, src type: {parsed.source.type}`
			)
		end
	end

	log.trace("dependencies in, moving onto crates")

	-- todo: crates

	return manifest_contents
end

function manifest.read_from(location: path.Pathlike): Identity
	log.trace("bringing manifest in")

	log.trace(`\treading file {location}`)
	const raw_contents = fs.readFileToString(location)

	return manifest.parse(raw_contents)
end

function manifest.find_closest_config(location: path.Pathlike): path.Pathlike?
	location = path.parse(location)

	local cursor = location
	for i = #location.parts, 1, -1 do
		cursor = path.normalize(path.join(cursor, ".."))

		const potential_config_path = path.join(cursor, CONFIG_FILE_NAME)

		if fs.exists(potential_config_path) then
			return potential_config_path
		end
	end

	return nil
end

return table.freeze(manifest)
