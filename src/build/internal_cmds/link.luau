const generate_linker_file = require("@src/build/utils/generate_linker_file")
const path = require("@std/path")

const function link(input: path.Pathlike, output: path.Pathlike)
	generate_linker_file(path.parse(input), path.parse(output))
end

return link
