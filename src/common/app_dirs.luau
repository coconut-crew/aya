const fs = require("@std/fs")
const path = require("@std/path")
const process = require("@std/process")
const system = require("@std/system")

export type AppDirectory = "state" | "config" | "data" | "cache" | "typedefs" | "bin"

const function windows_localappdata_path(): path.Path
	const local_appdata = process.env["LOCALAPPDATA"]
	assert(local_appdata and local_appdata ~= "", "LOCALAPPDATA is not set")

	return path.join(local_appdata, "coconutcrew", "aya")
end

const function env_var_default(var_name: string, fallback: path.Path): path.Path
	const env_var = process.env[var_name]
	if env_var == "" or env_var == nil then
		return fallback
	end

	return path.parse(env_var)
end

const lookups: { [AppDirectory]: () -> path.Path } = {
	["state"] = function()
		if system.win32 then
			return path.join(windows_localappdata_path(), "state")
		end

		const base = env_var_default("XDG_STATE_HOME", path.join(process.homedir(), ".local/state"))
		return path.join(base, "aya")
	end,

	["config"] = function()
		if system.win32 then
			return path.join(windows_localappdata_path(), "config")
		end

		const base = env_var_default("XDG_CONFIG_HOME", path.join(process.homedir(), ".config"))
		return path.join(base, "aya")
	end,

	["data"] = function()
		if system.win32 then
			return path.join(windows_localappdata_path(), "data")
		end

		const base = env_var_default("XDG_DATA_HOME", path.join(process.homedir(), ".local/share"))
		return path.join(base, "aya")
	end,

	["cache"] = function()
		if system.win32 then
			return path.join(windows_localappdata_path(), "cache")
		end

		const base = env_var_default("XDG_CACHE_HOME", path.join(process.homedir(), ".cache"))
		return path.join(base, "aya")
	end,

	["typedefs"] = function()
		-- intentional for ease of cross-platform environments
		return path.join(process.homedir(), ".aya/typedefs")
	end,

	["bin"] = function()
		if system.win32 then
			return path.join(windows_localappdata_path(), "bin")
		end

		return path.join(process.homedir(), ".local/bin")
	end,
}

const app_dirs = {
	lookup_cache = {} :: { [AppDirectory]: path.Path? },
}

-- the directory files of this kind should be written to
function app_dirs.get(kind: AppDirectory): path.Path
	const cache_entry = app_dirs.lookup_cache[kind]
	if cache_entry then
		return cache_entry
	end

	const location = lookups[kind]()
	app_dirs.lookup_cache[kind] = location

	return location
end

function app_dirs.ensure(kind: AppDirectory): path.Path
	const dir = app_dirs.get(kind)
	if not fs.exists(dir) then
		fs.createDirectory(dir, {
			makeParents = true,
		})
		return dir
	end

	assert(fs.type(dir) == "dir", `{path.format(dir)} is not a directory`)

	return dir
end

return table.freeze(app_dirs)
