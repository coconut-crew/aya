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

const semver_range = {
	operators = operators,

	-- matches every version, prereleases included
	any = table.freeze({ op = ">=", version = semver.zero }) :: Identity,
}

function semver_range.parse(text: string): Identity
	const length = if string.sub(text, 2, 2) == "=" then 2 else 1
	const op = operators[string.sub(text, 1, length)]

	return {
		op = op or error(`invalid range operator "{string.sub(text, 1, length)}" in "{text}"`),

		version = semver.parse(string.sub(text, length + 1)),
	}
end

function semver_range.prerelease_allowed(range: Identity, version: semver.Identity): boolean
	if not version.prerelease then
		return true
	end

	const target = range.version
	return target.prerelease ~= false
		and target.major == version.major
		and target.minor == version.minor
		and target.patch == version.patch
end

function semver_range.print(range: Identity): string
	if range == semver_range.any then
		return "*"
	end

	return `{range.op}{semver.print(range.version)}`
end

return table.freeze(semver_range)
