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

const semver = {}

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
		if tonumber(identifier) and has_leading_zeros(identifier) then
			error(string.format(LEADING_ZERO_ERR, "prerelease identifier", identifier, version_string))
		end
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
	returns true if left is newer than right
	
	it is like that for convenience sake in sort
]]
function semver.compare(left: Identity, right: Identity): boolean end

return table.freeze(semver)
