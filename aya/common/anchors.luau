const path = require("@std/path")
const process = require("@std/process")

const BUILD_DIR_ENV_KEY = "AYA_BUILD_DIR"
const PROJECT_DIR_ENV_KEY = "AYA_PROJECT_DIR"

const anchors = {}

function anchors.set(directory: path.Path)
	assert(path.isAbsolute(directory), `path {directory} must be absolute to be set as anchor`)

	process.env[PROJECT_DIR_ENV_KEY] = path.format(directory)
	process.env[BUILD_DIR_ENV_KEY] = path.format(path.join(directory, "build"))
end

function anchors.build(): path.Path
	return path.parse(process.env[BUILD_DIR_ENV_KEY])
end

function anchors.project(): path.Path
	return path.parse(process.env[PROJECT_DIR_ENV_KEY])
end

return anchors
