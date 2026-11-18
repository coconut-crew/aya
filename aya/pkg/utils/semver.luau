export type Identity = {
	major: number,
	minor: number,
	patch: number,

	prerelease: string | false,
}

-- gah damn
-- LLM generated string-pattern, well-tested
const SEMVER_PATTERN = "^(%d+)%.(%d+)%.(%d+)(%-?)([%w%.%-]*)%+?([%w%.%-]*)$"
const LEADING_ZERO_ERR = '%* "%*" in semver string "%*" has a leading zero, this is not allowed'

const function has_leading_zeros(num: string)
	return string.match(num, "^0%d") ~= nil
end

const function is_numeric(identifier: string): boolean
	return identifier ~= "" and string.find(identifier, "%D") == nil
end

-- also llm generated
const function order_identifiers(left: string, right: string): number
	const left_numeric, right_numeric = is_numeric(left), is_numeric(right)
	if left_numeric and right_numeric then
		return (tonumber(left) :: number) - (tonumber(right) :: number)
	end

	if left_numeric ~= right_numeric then
		return if left_numeric then -1 else 1
	elseif left == right then
		return 0
	elseif left < right then
		return -1
	else
		return 1
	end
end

--[[
	genuinely hate the semver spec
]]
const function order_prereleases(left: string | false, right: string | false): number
	if left == right then
		return 0
	elseif not left then
		-- a release is newer than any of its prereleases
		return 1
	elseif not right then
		return -1
	end

	const left_identifiers, right_identifiers = string.split(left, "."), string.split(right, ".")
	for index = 1, math.min(#left_identifiers, #right_identifiers) do
		const order = order_identifiers(left_identifiers[index], right_identifiers[index])
		if order ~= 0 then
			return order
		end
	end

	return #left_identifiers - #right_identifiers
end

const semver = {
	zero = {
		major = 0,
		minor = 0,
		patch = 0,

		prerelease = "0",
	} :: Identity,
}

--[[
	warning: No validation on prerelease,
	potential invariants can pop up here. Dont use user input.
]]
function semver.new(major: number, minor: number, patch: number, prerelease: string?): Identity
	return {
		major = major,
		minor = minor,
		patch = patch,

		prerelease = prerelease or false,
	}
end

--[[
	Can error (Will give error reason)
]]
function semver.parse(version_string: string): Identity
	const major, minor, patch, dash, prerelease, _ = string.match(version_string, SEMVER_PATTERN)
	assert(major, `invalid semver "{version_string}"`)

	const has_dash = dash ~= ""
	const has_prerelease = prerelease ~= ""
	-- if they're both there, its fine, if they're both absent, it's also fine
	assert(has_dash == has_prerelease, `invalid prerelease string "{version_string}"`)

	if has_leading_zeros(major) then
		error(string.format(LEADING_ZERO_ERR, "major version", major, version_string))
	elseif has_leading_zeros(minor) then
		error(string.format(LEADING_ZERO_ERR, "minor version", minor, version_string))
	elseif has_leading_zeros(patch) then
		error(string.format(LEADING_ZERO_ERR, "patch version", patch, version_string))
	end

	for identifier in string.gmatch(prerelease, "[%w%-]+") do
		assert(identifier ~= "", `empty prerelease identifier in semver string "{version_string}"`)
		assert(
			not (is_numeric(identifier) and has_leading_zeros(identifier)),
			string.format(LEADING_ZERO_ERR, "prerelease identifier", identifier, version_string)
		)
	end

	return {
		major = tonumber(major) :: number,
		minor = tonumber(minor) :: number,
		patch = tonumber(patch) :: number,

		prerelease = if has_prerelease then prerelease else false,
	}
end

function semver.compatible(left: Identity, right: Identity): boolean
	const left_major, right_major = left.major, right.major
	if left_major ~= right_major then
		return false
	end

	if left_major == 0 and left.minor ~= right.minor then
		return false
	end

	return true
end

--[[
	returns negative if older, positive if newer,
	and zero if equivalent
]]
function semver.compare(left: Identity, right: Identity): number
	if left.major ~= right.major then
		return left.major - right.major
	elseif left.minor ~= right.minor then
		return left.minor - right.minor
	elseif left.patch ~= right.patch then
		return left.patch - right.patch
	end

	return order_prereleases(left.prerelease, right.prerelease)
end

--[[
	returns true if left is newer than right

	it is like that for convenience sake in sort
]]
function semver.newer(left: Identity, right: Identity): boolean
	return semver.compare(left, right) > 0
end

function semver.older(left: Identity, right: Identity): boolean
	return semver.compare(left, right) < 0
end

function semver.print(version: Identity): string
	const base = `{version.major}.{version.minor}.{version.patch}`
	return if version.prerelease then `{base}-{version.prerelease}` else base
end

return table.freeze(semver)
