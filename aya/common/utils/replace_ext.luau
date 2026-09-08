-- this is ai generated btw if it blows up dont blame me blame israel
const path = require("@std/path")

--- Returns `input` with the extension of its last component replaced by `new_ext`,
--- e.g. `src/main.luau` -> `src/main.dd`. `new_ext` may be written with or without a
--- leading dot, and an empty `new_ext` strips the extension entirely. Components with
--- no extension gain one; paths with no last component (roots) are returned unchanged.
const function replace_ext(input: path.Path, new_ext: string): path.Path
	const file_name = path.basename(input)

	if file_name == nil then
		return path.parse(input)
	end

	const dot_ext = if new_ext == "" or string.sub(new_ext, 1, 1) == "." then new_ext else "." .. new_ext
	const extension = path.extname(input)
	const stem = string.sub(file_name, 1, #file_name - #extension)
	const dir = path.dirname(input)

	if dir == "." then
		return path.parse(stem .. dot_ext)
	end

	return path.join(dir, stem .. dot_ext)
end

return replace_ext
