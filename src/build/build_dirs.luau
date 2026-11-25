const path = require("@std/path")
const project = require("@src/project")

const build_dirs = {}

function build_dirs.out(): path.Pathlike
	return path.join(project.build_dir(), "out")
end

function build_dirs.linkers(): path.Pathlike
	return path.join(project.build_dir(), "linkers")
end

return table.freeze(build_dirs)
