const app_dirs = require("@src/common/app_dirs")
const fs = require("@std/fs")
const json = require("@vendor/json")
const path = require("@std/path")
const setting = require("@src/config/setting")
const settings = require("@src/config/settings")

-- todo fix this
export type Values = {
	["exec_path.ninja"]: string,
}

const function config_path(): path.Path
	return path.join(app_dirs.get("config"), "config.json")
end

const function read_config(): { [string]: string }
	const location = config_path()
	if not fs.exists(location) then
		return {}
	end

	const stored = json.deserialize(fs.readFileToString(location)) :: any
	assert(type(stored) == "table", "config.json must contain an object")

	return stored
end

const function set_setting(key: string, text: string?)
	const stored = read_config()
	stored[key] = text

	app_dirs.ensure("config")
	fs.writeStringToFile(config_path(), json.serialize(json.object(stored :: any), true))
end

const config = {}

function config.path(): path.Path
	return config_path()
end

function config.read(): Values
	const stored = read_config()
	const values = {}

	for key, found in settings :: { [string]: setting.Identity<any> } do
		const text = stored[key]
		assert(text == nil or type(text) == "string", `{key} must be stored as a string`)

		values[key] = if text == nil then found.default else found.parse(text)
	end

	return values :: any
end

function config.get(key: string): unknown
	assert((settings :: { [string]: setting.Identity<any> })[key], `unknown setting {key}`)

	return (config.read() :: any)[key]
end

function config.set(key: string, text: string)
	const found = (settings :: { [string]: setting.Identity<any> })[key]
	assert(found, `unknown setting {key}`)

	found.parse(text)
	set_setting(key, text)
end

function config.unset(key: string)
	assert((settings :: { [string]: setting.Identity<any> })[key], `unknown setting {key}`)
	set_setting(key, nil)
end

return table.freeze(config)
