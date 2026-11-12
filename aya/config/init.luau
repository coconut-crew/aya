const anchors = require("@aya/common/anchors")
const fs = require("@std/fs")
const path = require("@std/path")
const pkg_types = require("@aya/pkg/pkg_types")
const toml = require("@vendor/toml")
const type_fns = require("@vendor/type_fns")

const CONFIG_FILE_NAME = ".aya.toml"

export type WorkspaceConfig = {
	dependencies: {
		[string]: pkg_types.Install,
	},

	packages: { path.Pathlike },
}

export type CrateConfig =
	| {
		type: "lib",
		needs: { string },
	}
	| {
		type: "task",
		alias: string,
		needs: { string },
	}

export type PackageConfig = {
	name: string,

	dependencies: {},
}

export type Identity = {
	workspace: WorkspaceConfig,

	package: {
		bin: {},
	},
}

const config = {}

function config.get_workspace_config(): WorkspaceConfig
	const config_path = path.join(anchors.workspace(), CONFIG_FILE_NAME)
	const config_string = fs.readFileToString(config_path)
	const config_content = toml.deserialize(config_string)

	return config_content :: any
end

function config.find_closest_config(loc: path.Pathlike): path.Pathlike?
	loc = path.parse(loc)

	local cursor = loc
	for i = #loc.parts, 1, -1 do
		cursor = path.normalize(path.join(cursor, ".."))

		const potential_config_path = path.join(cursor, CONFIG_FILE_NAME)

		if fs.exists(potential_config_path) then
			return potential_config_path
		end
	end

	return nil
end

function config.validate(data: string): Identity
	return toml.deserialize(data) :: any
end

return table.freeze(config)
