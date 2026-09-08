const fs = require("@std/fs")
const path = require("@std/path")
const toml = require("@vendor/toml")

export type Dependency = {
	remote: string,
	branch: string,
	commit: string,
}

export type Identity = {
	name: string,
	entry_point: string | false,

	dependency: { [string]: Dependency },
}

const manifest = {}

function manifest.read(location: path.Path)
	const file_contents = fs.readFileToString(location)
	const configuration = toml.deserialize(file_contents)

	-- guarantee it to be empty just because it's a real pain in the fucking ass for it to be nullable
	if not configuration.dependency then
		configuration.dependency = {}
	end

	return manifest.validate(configuration)
end

function manifest.get_pkg_manifest(dependency: string): Identity
	return manifest.read(path.parse(`packages/_index/{dependency}/ayapkg.toml`))
end

function manifest.validate(input: any): Identity
	assert(type(input) == "table", "input must be a table")

	for _, value in input.dependency do
		assert(type(value.commit) == "string", "commit")
		assert(type(value.remote) == "string", "remote")
		assert(type(value.branch) == "string", "branch")
	end

	return input
end

function manifest.write(input: Identity, loc: path.Path)
	fs.writeStringToFile(loc, toml.serialize(input :: any))
end

return manifest
