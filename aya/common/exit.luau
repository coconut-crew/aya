const colorful = require("@pkg/colorful")
const log = require("@aya/common/log")
const process = require("@std/process")

export type ExitCode = "MANIFEST_PARSING_FAILED" | "ASSERTION_FAILED" | "WORKSPACE_NO_MANIFEST"
export type ExitReason = {
	code: number,
	explanation: { string },
}

const styles = colorful.styles

const reasons: { [ExitCode]: ExitReason } = {
	["MANIFEST_PARSING_FAILED"] = {
		code = 1,
		explanation = {
			`Manifest {styles.keyword("%*")} failed to parse: %*.`,
		},
	},

	["ASSERTION_FAILED"] = {
		code = 1,
		explanation = {
			`ASSERTION FAILED: %*`,
		},
	},

	["WORKSPACE_NO_MANIFEST"] = {
		code = 1,
		explanation = {
			"The workspace has no .aya.toml manifest",
		},
	},
}

const function exit(why: "" | ExitCode, ...: string): never
	const data = reasons[why :: any]
	log.err(string.format(table.concat(data.explanation, "\n"), ...))

	return process.exit(data.code)
end

return exit
