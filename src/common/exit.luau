const colorful = require("@pkg/colorful")
const log = require("@src/common/log")
const process = require("@std/process")

export type ExitCode =
	"MANIFEST_PARSING_FAILED"
	| "ASSERTION_FAILED"
	| "WORKSPACE_NO_MANIFEST"
	| "ANCHOR_ENV_VARS_MISSING"
export type ExitReason = {
	code: number,
	explanation: { string },
}

const styles = colorful.styles

const reasons: { [ExitCode]: ExitReason } = {
	["MANIFEST_PARSING_FAILED"] = {
		code = 1,
		explanation = {
			`manifest {styles.keyword("%*")} failed to parse: %*`,
		},
	},

	["ASSERTION_FAILED"] = {
		code = 1,
		explanation = {
			`ASSERTION FAILED: %*`,
			"this is an internal issue, please @ffrostfall",
		},
	},

	["WORKSPACE_NO_MANIFEST"] = {
		code = 1,
		explanation = {
			"the workspace has no .aya.yaml manifest",
		},
	},

	["ANCHOR_ENV_VARS_MISSING"] = {
		code = 1,
		explanation = {
			`missing environment variables: %*`,
			"likely an internal issue, @ffrostfall",
		},
	},
}

const function exit(why: "" | ExitCode, ...: string): never
	const data = reasons[why :: any]
	log.err(string.format(table.concat(data.explanation, "\n"), ...))

	return process.exit(data.code)
end

return exit
