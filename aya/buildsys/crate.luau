const anchors = require("@aya/common/anchors")
const fs = require("@std/fs")
const generate_linker_file = require("@aya/common/generate_linker_file")
const generate_uuid = require("@aya/common/utils/generate_uuid")
const json = require("@vendor/json")
const luninjau = require("@pkgs/luninjau")
const path = require("@std/path")
const pretty_print = require("@aya/common/utils/pretty_print")
const process = require("@std/process")

const crate = {
	uuid_map = {} :: { [string]: string? },
}

--[=[
	adds a files crate-uuid maps to the current luau session's map
]=]
function crate.import_uuids_async(from: path.Pathlike?)
	const cratemap_path = from or path.join(anchors.build(), "cratemap")
	if not fs.exists(cratemap_path) then
		return
	end

	const cratemap_string = fs.readFileToString(cratemap_path)

	for crate_name, crate_value in string.gmatch(cratemap_string, "([^=,]-)%s*=%s*([^=,]-)%s*,") do
		crate.uuid_map[path.format(path.parse(crate_name))] = crate_value
	end
end

function crate.export_uuids_async(to: path.Pathlike?)
	if not next(crate.uuid_map) then
		fs.writeStringToFile(to or path.join(anchors.build(), "cratemap"), "")
		return
	end

	const elements = {}

	for key, value in crate.uuid_map do
		table.insert(elements, `{path.format(path.parse(key))}={value}`)
	end

	fs.writeStringToFile(to or path.join(anchors.build(), "cratemap"), table.concat(elements, ",") .. ",")
end

--[=[
	fetches the unique ID for a crate
	
	this is stored in `build/cratemap`, if it is not there a new one will be generated
]=]
function crate.uuid_async(self: Identity): string
	const format_str = path.format(self.dir)
	const entry = crate.uuid_map[format_str]
	if not entry then
		const uuid = generate_uuid()
		crate.uuid_map[path.format(path.parse(self.dir))] = uuid

		return uuid
	end

	return entry
end

function crate.build_configs(self: Identity)
	crate.import_uuids_async()
end

return table.freeze(crate)
