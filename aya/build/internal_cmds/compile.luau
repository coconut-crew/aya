const fs = require("@std/fs")
const path = require("@std/path")

const function compile(src: path.Pathlike, dst: path.Pathlike)
	const src_content = fs.readFileToString(src)

	fs.writeStringToFile(dst, src_content)
end

return compile
