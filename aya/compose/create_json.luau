const json = require("@agnostic/utils/json")

export type RojoProject = {
	name: string,
	tree: RojoTree,
	emitLegacyScripts: false,

	gameId: string?,
	placeId: number?,
	servePlaceIds: { number }?,
	serveAddress: string?,
	servePort: number?,
	globIgnorePaths: { string }?,
}

export type RojoTree = {
	[string]: RojoTree,

	["$className"]: string?,
	["$path"]: string | { optional: string }?,
	["$ignoreUnknownInstances"]: boolean?,
	["$properties"]: { [string]: json.Value }?,
}

const function print_target_json(target: string): string
	const tree: RojoTree = {
		["$className"] = "Folder",

		["$path"] = `./{target}`,
	}

	const project = {
		name = target,

		tree = tree,
		emitLegacyScripts = false,
	}

	return json.serialize(project, true)
end

return {
	print_target_json = print_target_json,
}
