const exit = require("@aya/common/exit")
const fs = require("@std/fs")
const path = require("@std/path")
const toml = require("@vendor/toml")

const CONFIG_FILE_NAME = ".aya.toml"

export type ManifestDepEntry =
	{
		name: string,
		version: string,
	}
	| {
		name: string,
		version: string,
		github: string,
	}

export type TableRepresentation = {
	dependencies: {
		[string]: {
			version: string,
		} | {
			version: string,
			github: string,
		},
	},
}

export type Identity = {}

const manifest = {}

function manifest.read_from(location: path.Pathlike): Identity
	const raw_contents = fs.readFileToString(location)
	const ok, res = pcall(toml.deserialize, raw_contents)
	if not ok then
		return exit("MANIFEST_PARSING_FAILED", path.format(location), tostring(res))
	end
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
