const create_json = require("@self/create_json")
const fs = require("@std/fs")
const path = require("@std/path")
const process = require("@std/process")
const anchors = require("@common/anchors")
const path_to_file_name = require("@common/utils/path_to_file_name")
--[[
steps:

- generates a project json for the target
- invoke rojo build into a rbxm
]]

const function build_rbxm(target: string)
	const json_file = create_json.print_target_json(target)
	const path = path_to_file_name(anchors.build(), path.parse(`./{target}.project.json`))
	fs.writeStringToFile(path, json_file)

	return process.run({ "rojo", "build", "-o", `{target}.rbxm` })
end
