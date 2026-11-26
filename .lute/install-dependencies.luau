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
	assert(string.find(dep_name, "^[%w_%-]+$"), `invalid dependency name {dep_name}`)
	assert(string.find(dep_data.commit, "^%x+$"), `{dep_name}.commit must be a hex hash`)
	assert(string.sub(dep_data.remote, 1, 8) == "https://", `{dep_name}.remote must be an https url`)

	--TODO: dont nuke it, fetch instead.
	if fs.exists(`pkgs/index/{dep_name}`) then
		fs.removeDirectory(`pkgs/index/{dep_name}`, {
			recursive = true,
		})
	end

	const res = process.run({
		"git",
		"clone",
		"--depth=1",
		`--revision={dep_data.commit}`,
		"--",
		dep_data.remote,
		`pkgs/index/{dep_name}`,
	}, {
		stdio = "inherit",
	})

	assert(res.ok, `failed to clone dependency {dep_name} (got {res.exitcode}):\n{res.stderr}`)

	const head = process.run({ "git", "-C", `pkgs/index/{dep_name}`, "rev-parse", "HEAD" })
	assert(head.ok, `failed to read checked out commit of {dep_name}`)
	assert(
		string.sub(string.lower(head.stdout), 1, #dep_data.commit) == string.lower(dep_data.commit),
		`{dep_name} checked out {head.stdout} instead of {dep_data.commit}`
	)

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
