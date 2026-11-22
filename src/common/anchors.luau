const path = require("@std/path")
const process = require("@std/process")

const BUILD_DIR_ENV_KEY = "AYA_BUILD"
const WORKSPACE_DIR_ENV_KEY = "AYA_WORKSPACE"

const anchors = {}

function anchors.set(directory: path.Pathlike)
	assert(path.isAbsolute(directory), `path {directory} must be absolute to be set as anchor`)

	process.env[WORKSPACE_DIR_ENV_KEY] = path.format(directory)
	process.env[BUILD_DIR_ENV_KEY] = path.format(path.join(directory, "build"))
end

function anchors.build(): path.Path
	return path.parse(process.env[BUILD_DIR_ENV_KEY])
end

function anchors.workspace(): path.Path
	return path.parse(process.env[WORKSPACE_DIR_ENV_KEY])
end

return anchors
