const path = require("@std/path")

export type DependencyConfig =
	{
		name: string,
		version: string,
	}
	| {
		name: string,
		version: string,
		github: string,
	}

--[[
	Build object types
]]
export type CrateId = string
export type PackageId = string

export type Crate = {
	package: string,
	name: string,

	-- Relative to anchor.root
	dir: path.Pathlike,

	exports: { path.Pathlike },
	needs: { path.Pathlike },
}

export type Package = {
	name: string,

	crates: { CrateId },
}

return nil
