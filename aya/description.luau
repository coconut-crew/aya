--	Builds a description of the project:
--		- Package dependency graph
--		- All the crates

const anchors = require("@aya/common/anchors")
const config = require("@aya/config")

export type Identity = {
	dependency_list: {},
}

const description = {}

function description.build_description()
	const workspace_config = config.get_workspace_config()

	for alias, dependency in workspace_config.dependencies do
	end
end

return table.freeze(description)
