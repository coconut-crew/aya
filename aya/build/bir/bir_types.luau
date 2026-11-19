const path = require("@std/path")

type LinkCratePair = {
	link_location: path.Pathlike,
	src: path.Pathlike,
}

export type BirCompileLuauObject = {
	stat: "compile",

	--- Relative to workspace
	src: path.Pathlike,

	--- Relative to build
	dst: path.Pathlike,

	vars: { [string]: string },
}

export type BirLinkCrates = {
	stat: "link_crates",

	--- Relative to workspace
	dir: path.Pathlike,

	links: { LinkCratePair },
}

export type BirStat = | BirCompileLuauObject | BirLinkCrates

return nil
