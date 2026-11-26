const config = require("@src/config")
const log = require("@src/common/log")
const process = require("@std/process")

const function build(): never
	const ninja = config.read()["exec_path.ninja"]

	-- lute exits 0 on an uncaught error after a failed spawn, so exit explicitly
	const spawned, result = pcall(process.run, { ninja }, { stdio = "inherit" } :: any)
	if not spawned then
		log.err(`failed to run {ninja}: {result}`)
		return process.exit(1)
	end

	return process.exit(result.exitcode)
end

return build
