const dev_generate_linker_file = require("./src/dev_generate_linker_file")
const fs = require("@std/fs")
const path = require("@std/path")
const process = require("@std/process")
const system = require("@std/system")
const toml = require("@vendor/toml")

if not fs.exists("pkgs/index") then
	fs.createDirectory("pkgs/index", { makeParents = true })
end

if not fs.exists("pkgs/links") then
	fs.createDirectory("pkgs/links", { makeParents = true })
end

for dep_name, dep_data: any in toml.deserialize(fs.readFileToString("dependencies.toml")) do
	dep_data = dep_data :: unknown
	assert(type(dep_data) == "table", `dependency {dep_name} is not an object`)
	assert(type(dep_data.commit) == "string", `{dep_name}.commit must be a string`)
	assert(type(dep_data.remote) == "string", `{dep_name}.remote must be a string`)
	assert(type(dep_data.branch) == "string", `{dep_name}.branch must be a string`)
	assert(type(dep_data.entry_point) == "string", `{dep_name}.entry_point must be a string`)

	--TODO: dont nuke it, fetch instead.
	if fs.exists(`pkgs/index/{dep_name}`) then
		fs.removeDirectory(`pkgs/index/{dep_name}`, {
			recursive = true,
		})
	end

	const res = process.system(
		`git clone --depth=1 --revision={dep_data.commit} {dep_data.remote} pkgs/index/{dep_name}`,
		{
			stdio = "inherit",
		}
	)

	assert(res.ok, `failed to clone dependency {dep_name} (got {res.exitcode}):\n{res.stderr}`)

	dev_generate_linker_file(
		path.join(`pkgs/index/{dep_name}`, dep_data.entry_point),
		path.join(`pkgs/links/{dep_name}.luau`)
	)
end

for dep_name, dep_data: any in toml.deserialize(fs.readFileToString("dependencies.toml")) do
	dep_data = dep_data :: unknown
	assert(type(dep_data) == "table", `dependency {dep_name} is not an object`)
	assert(type(dep_data.commit) == "string", `{dep_name}.commit must be a string`)
	assert(type(dep_data.remote) == "string", `{dep_name}.remote must be a string`)
	assert(type(dep_data.branch) == "string", `{dep_name}.branch must be a string`)
	assert(type(dep_data.entry_point) == "string", `{dep_name}.entry_point must be a string`)

	for link_name in toml.deserialize(fs.readFileToString("dependencies.toml")) do
		if link_name == dep_name then
			continue
		end

		fs.createDirectory(`pkgs/index/{link_name}/pkgs/links`, {
			makeParents = true,
		})

		dev_generate_linker_file(
			path.join(`pkgs/index/{dep_name}`, dep_data.entry_point),
			path.join(`pkgs/index/{link_name}/pkgs/links/{dep_name}.luau`)
		)
	end
end
