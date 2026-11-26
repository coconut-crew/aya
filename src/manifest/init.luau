const fs = require("@std/fs")
const log = require("@src/common/log")
const m_dependency_parser = require("@src/manifest/m_dependency_parser")
const path = require("@std/path")
const pkg_id = require("@src/pkg/utils/pkg_id")
const semver = require("@src/pkg/utils/semver")
const semver_range = require("@src/pkg/utils/semver_range")
const source_info = require("@src/pkg/sources/source_info")
const yaml_luau = require("@pkg/yaml_luau")

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

type RawCrateEntry = {
	needs: { string },
	exports: { string },
	dir: string,
}

type RawTableRepresentation = {
	package: {
		name: string,
		version: string?,
	}?,

	dependencies: {
		[string]: RawDepEntry,
	},

	crates: {
		[string]: RawCrateEntry,
	},
}

export type Identity = {
	version: semver.Identity,

	dependencies: { [pkg_id.GlobalName]: DependencyEntry },
}

const CONFIG_FILE_NAME = ".aya.yaml"

const function null_to_nil(value: any): any
	return if value == yaml_luau.null then nil else value
end

const manifest = {
	CONFIG_FILE_NAME = CONFIG_FILE_NAME,
}

function manifest.parse(str_content: string): Identity
	log.trace(`\tparsing yaml`)

	const document = null_to_nil((yaml_luau.deserialize(str_content))) or {}
	-- yaml sequences are tables too, but always have array entries
	assert(type(document) == "table" and #document == 0, "the manifest must be a mapping")

	const raw_table_representation: RawTableRepresentation = document

	log.trace("got yaml, converting into internal format")

	const raw_package = null_to_nil(raw_table_representation.package)
	const raw_version = if raw_package then null_to_nil(raw_package.version) else nil
	assert(raw_version == nil or type(raw_version) == "string", "package.version must be a string")

	const manifest_contents: Identity = {
		version = if raw_version then semver.parse(raw_version) else semver.parse("0.0.0"),
		dependencies = {},
	}

	const raw_dependencies = null_to_nil(raw_table_representation.dependencies)
	if raw_dependencies ~= nil then
		assert(type(raw_dependencies) == "table", "the dependencies entry must be a table")

		for dependency, data in raw_dependencies do
			const parsed = m_dependency_parser.parse_dep(dependency, data)
			assert(
				manifest_contents.dependencies[parsed.global_name] == nil,
				`duplicate dependency {parsed.global_name}, names are case insensitive`
			)

			manifest_contents.dependencies[parsed.global_name] = parsed

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
	-- relative locations have to be made absolute, or the walk stops at the working directory
	local cursor = path.resolve(location)

	while true do
		const potential_config_path = path.join(cursor, CONFIG_FILE_NAME)
		if fs.exists(potential_config_path) then
			return potential_config_path
		end

		if #cursor.parts == 0 then
			return nil
		end

		cursor = path.resolve(cursor, "..")
	end
end

return table.freeze(manifest)
