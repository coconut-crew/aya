const path = require("@std/path")

const function path_to_file_name(anchor: path.Path, input: path.Path): string
	if not path.isAbsolute(input) then
		input = path.resolve(input)
	end
	const joined = path.relative(anchor, input)
	const file_name = path.basename(joined) or ""
	const dir = (string.gsub(path.dirname(joined), "\\", "."))

	return dir .. "_" .. file_name
end

return path_to_file_name
