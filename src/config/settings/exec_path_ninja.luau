const setting = require("@src/config/setting")

const exec_path_ninja: setting.Identity<string> = {
	description = "ninja executable path",
	default = "ninja",

	parse = function(text: string): string
		assert(text ~= "", "the ninja executable path cannot be empty")
		return text
	end,
}

return exec_path_ninja
