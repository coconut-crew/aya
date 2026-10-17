const fs = require("@std/fs")
const path = require("@std/path")
const process = require("@std/process")

export type InstallationDirectoryInterface = {
	write_file: (loc: path.Path, contents: string) -> (),
}

const installation = {}

function installation.register_dir(name: string): InstallationDirectoryInterface
	const function directory_write_file(file: path.Pathlike, contents: string)
		fs.writeStringToFile(path.join(process.homedir(), ".aya", name, file), contents)
	end

	return {
		write_file = directory_write_file,
	}
end

function installation.run_setup()
	const home_dir = process.homedir()
	const aya_user_folder = path.join(home_dir, ".aya")

	if fs.exists(aya_user_folder) then
		return
	else
		fs.createDirectory(aya_user_folder)
	end
end

return installation
