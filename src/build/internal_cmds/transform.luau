const fs = require("@std/fs")
const json = require("@vendor/json")
const path = require("@std/path")

const function transform(src: path.Pathlike, dst: path.Pathlike, plan: path.Pathlike)
	const src_content = fs.readFileToString(src)

	const plan_contents = json.deserialize(fs.readFileToString(plan))

	fs.writeStringToFile(dst, src_content)
end

return transform
