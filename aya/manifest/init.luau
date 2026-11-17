const exit = require("@aya/common/exit")
const fs = require("@std/fs")
const log = require("@aya/common/log")
const path = require("@std/path")
const pkg_id = require("@aya/pkg/pkg_id")
const pretty_print = require("@aya/common/utils/pretty_print")
const provider = require("@aya/pkg/provider")
const semver_range = require("@aya/pkg/utils/semver_range")
const toml = require("@vendor/toml")

const CONFIG_FILE_NAME = ".aya.toml"

type DependencyEntry = {
	global_name: pkg_id.GlobalName,
	version: semver_range.Identity,
	source: provider.SourceInfo,
}

type RawDepEntry =
	{
		version: string,
		github: nil,
	}
	| {
		version: string,
		github: string,
	}

type RawTableRepresentation = {
	dependencies: {
		[string]: RawDepEntry,
	},
}

export type Identity = {
	dependencies: { [pkg_id.GlobalName]: DependencyEntry },
}

const function parse_raw_dependency(raw_name: string, raw: RawDepEntry): DependencyEntry
	const global_name = pkg_id.global_name(raw_name)

	local version_string = raw.version
	if not semver_range.operators[string.sub(raw.version, 1, 1)] then
		version_string = "^" .. raw.version
	end

	const version = semver_range.parse(version_string)

	if raw.github then
		return {
			global_name = global_name,
			version = version,

			source = {
				type = "git",
				remote = `https://github.com/{raw.github}/{global_name}.git`,
			},
		}
	else
		error("non-github dependencies are unsupported at this time")
	end
end

const manifest = {}

function manifest.parse(str_content: string): Identity
	log.trace(`\tparsing toml`)

	const raw_table_representation = toml.deserialize(str_content) :: RawTableRepresentation

	log.trace("got toml, converting into internal format")

	const raw_dependencies = raw_table_representation.dependencies
	assert(type(raw_dependencies) == "table", "the dependencies entry must be a table")

	const manifest_contents: Identity = {
		dependencies = {},
	}

	for dependency, data in raw_dependencies do
		const parsed = parse_raw_dependency(dependency, data)

		manifest_contents.dependencies[dependency] = parsed

		log.trace(
			`\tparsed dep [{dependency}]: v{semver_range.print(parsed.version)}, src type: {parsed.source.type}`
		)
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

manifest.read_from(".aya.toml")

return table.freeze(manifest)
