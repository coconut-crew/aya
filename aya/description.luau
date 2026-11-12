--	Builds a description of the project:
--		- Package dependency graph
--		- All the crates

const anchors = require("@aya/common/anchors")
const config = require("@aya/config")
const fs = require("@std/fs")
const path = require("@std/path")
const pkg = require("@aya/cmds/pkg")

export type Package = {
	crates: {
		[string]: Crate,
	},

	needs: { string },
}

export type Identity = {
	external_dependencies: nil,

	packages: { [string]: Package },
}

const description = {}

function description.build_description(): Identity
	const build_description = {
		external_dependencies = {},

		packages = {},
	}

	const workspace_config = config.get_workspace_config()

	for alias, dependency in workspace_config.dependencies do
		print(`dep {alias} from {dependency}`)
	end

	for alias, package in workspace_config.packages do
		const package_config = fs.readFileToString(config.find_closest_config(package) or error("todo error message"))
		const data = config.validate(package_config)
	end
end

return table.freeze(description)
