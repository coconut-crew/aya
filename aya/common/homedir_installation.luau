const fs = require("@std/fs")
const path = require("@std/path")
const process = require("@std/process")

const homedir_installation = {}

function homedir_installation.register_dir(name: string): path.Path
	return path.join(process.homedir(), ".aya", name)
end

function homedir_installation.run_setup()
	const home_dir = process.homedir()
	const aya_user_folder = path.join(home_dir, ".aya")

	if fs.exists(aya_user_folder) then
		return
	else
		fs.createDirectory(aya_user_folder)
	end
end

return homedir_installation
