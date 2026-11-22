const process = require("@std/process")

const function build()
	process.run({ "ninja" })
end

return build
