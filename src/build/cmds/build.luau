const config = require("@src/config")
const process = require("@std/process")

const function build(): never
	const result = process.run({ config.read()["exec_path.ninja"] }, { stdio = "inherit" })
	return process.exit(result.exitcode)
end

return build
