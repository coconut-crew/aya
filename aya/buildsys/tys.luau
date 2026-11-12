const path = require("@std/path")

--[[
	Crates
]]

-- uuid
export type CrateId = string

export type Crate = {
	name: string,

	-- Relative to anchor.root
	dir: path.Pathlike,

	exports: { path.Pathlike },
	needs: { path.Pathlike },
}

--[[
	Packages
]]

-- uuid
export type PackageId = string

export type Package = {
	name: string,

	crates: { CrateId },
}

return nil
