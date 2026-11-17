const fs = require("@std/fs")
const path = require("@std/path")
const toml = require("@vendor/toml")

export type Identity = {}

const LOCKFILE_NAME = ".aya.lock.toml"

const lockfile = {}

function lockfile.parse(content: string): Identity
	const deserialized = toml.deserialize(content)

	return deserialized
end

function lockfile.serialize(locked: Identity): string
	return toml.serialize(locked :: any)
end

function lockfile.write(file: Identity, to: path.Pathlike)
	fs.writeStringToFile(to, lockfile.serialize(file))
end

function lockfile.read(dir: path.Pathlike): Identity?
	const location = path.join(dir, LOCKFILE_NAME)

	if fs.exists(location) then
		const file_content = fs.readFileToString(location)

		return lockfile.parse(file_content)
	else
		return nil
	end
end

return table.freeze(lockfile)
