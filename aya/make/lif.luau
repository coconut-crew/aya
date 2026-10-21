const json = require("@std/json")
const luau = require("@std/luau")
const path = require("@std/path")

export type LuauImport = {
	raw: string,
	resolved: path.Path,
}

export type File = {
	imports: { LuauImport },
	exports: nil,
}

const lif = {}

function lif.read(file: path.Path): File
	const lif_result: File = {
		imports = {},
		exports = nil,
	}

	const req_nodes = luau.requires(file)

	return lif_result
end

function lif.write() end

return lif
