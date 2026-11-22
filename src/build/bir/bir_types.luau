const path = require("@std/path")

--[=[
	All paths are relative to anchors.build() unless stated otherwise
]=]

type LinkCratePair = {
	link_location: path.Pathlike,

	--- Relative to workspace
	src: path.Pathlike,
}

export type BirTransformLuauObject = {
	stat: "transform",

	--- Relative to workspace
	src: path.Pathlike,

	dst: path.Pathlike,

	vars: { [string]: string },
}

export type BirLinkCrates = {
	stat: "link_crates",

	--- Relative to workspace
	dir: path.Pathlike,

	links: { LinkCratePair },
}

export type BirCompileBinStat = {
	stat: "compile_bin",

	src: path.Pathlike,
	dst: path.Pathlike,
}

export type BirStat = | BirTransformLuauObject | BirLinkCrates | BirCompileBinStat

return nil
