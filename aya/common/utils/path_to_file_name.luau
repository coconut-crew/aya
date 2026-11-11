const path = require("@std/path")

const function path_to_file_name(anchor: path.Path, input: path.Path): string
	if not path.isAbsolute(input) then
		input = path.resolve(input)
	end

	const parts = path.relative(anchor, input).parts
	const file_name = table.remove(parts) or ""

	return table.concat(parts, ".") .. "_" .. file_name
end

return path_to_file_name
