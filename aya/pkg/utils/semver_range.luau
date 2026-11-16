const interval_set = require("@aya/common/utils/interval_set")
const semver = require("@aya/pkg/utils/semver")

export type RangeOperators = "^" | "~" | "=" | "<" | ">" | "<=" | ">="

export type Identity = {
	op: RangeOperators,

	version: semver.Identity,
}

const operators: { [string]: RangeOperators } = {
	["^"] = "^",
	["~"] = "~",
	["="] = "=",
	["<"] = "<",
	[">"] = ">",
	["<="] = "<=",
	[">="] = ">=",
}

const semver_range = {}

function semver_range.parse(text: string): Identity
	const length = if string.sub(text, 2, 2) == "=" then 2 else 1
	const op = operators[string.sub(text, 1, length)]

	return {
		op = op
			or error(`invalid range operator {string.sub(text, 1, length)} in semver range {text}`),

		version = semver.parse(string.sub(text, length + 1)),
	}
end

function semver_range.print(range: Identity): string
	return `{range.op}{semver.print(range.version)}`
end

return table.freeze(semver_range)
