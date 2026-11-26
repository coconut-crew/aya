const path = require("@std/path")
const setting = require("@src/config/setting")

const exec_path_ninja: setting.Identity<string> = {
	description = "ninja executable path",
	default = "ninja",

	parse = function(text: string): string
		if not path.parse(text) then
		end
		return text
	end,
}

return exec_path_ninja
