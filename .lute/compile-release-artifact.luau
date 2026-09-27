const fs = require("@std/fs")
const process = require("@std/process")
const system = require("@std/system")

if not fs.exists("release") then
	fs.createDirectory("release")
end

if not fs.exists("release/bin") then
	fs.createDirectory("release/bin")
end

const binary_name = process.env["BINARY"]
const exec_path = `release/bin/{binary_name}`

const res = process.run({ "lute", "compile", "./aya/init.luau", "--output", exec_path }, {
	stdio = "inherit",
})

if system.win32 then
	-- { "Compress-Archive", "-Path", `"{exec_path}"`, "-DestinationPath", `release/{exec_path}.tar.gz` }
	process.system(`Compress-Archive -Path "{exec_path}" -DestinationPath "release/{binary_name}.zip"`, {
		stdio = "inherit",
		system = "powershell",
	})
else
	process.run({ "tar", "-czvf", `release/{binary_name}.tar.gz`, exec_path })
end

process.exit(res.exitcode)
