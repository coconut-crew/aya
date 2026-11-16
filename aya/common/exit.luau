const colorful = require("@pkg/colorful")
const log = require("@aya/common/log")
const process = require("@std/process")

export type ExitCode = "MANIFEST_PARSING_FAILED" | "ASSERTION_FAILED"
export type ExitReason = {
	code: number,
	explanation: { string },
}

const styles = colorful.styles

const reasons: { [ExitCode]: ExitReason } = {
	["MANIFEST_PARSING_FAILED"] = {
		code = 1,
		explanation = {
			`Failed to parse manifest at {styles.keyword("%*")}\n\t%*.`,
		},
	},

	["ASSERTION_FAILED"] = {
		code = 1,
		explanation = {
			`ASSERTION FAILED: %*`,
		},
	},
}

const function exit(why: "" | ExitCode, ...: string): never
	const data = reasons[why :: any]
	log.err(string.format(table.concat(data.explanation, "\n"), ...))

	return process.exit(data.code)
end

return exit
