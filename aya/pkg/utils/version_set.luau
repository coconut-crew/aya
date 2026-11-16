const interval_set = require("@aya/common/utils/interval_set")
const semver = require("@aya/pkg/utils/semver")
const semver_range = require("@aya/pkg/utils/semver_range")

export type Identity = interval_set.Identity<semver.Identity>

--[[
	AI generated implementations begin
]]

const function successor(version: semver.Identity): semver.Identity
	const major, minor, patch = version.major, version.minor, version.patch
	if version.prerelease then
		return semver.new(major, minor, patch, `{version.prerelease}.0`)
	end

	return semver.new(major, minor, patch + 1, "0")
end

const function lower_bound(range: semver_range.Identity): semver.Identity
	if range.op == "<" or range.op == "<=" then
		return semver.zero
	elseif range.op == ">" then
		return successor(range.version)
	end

	return range.version
end

const function upper_bound(range: semver_range.Identity): semver.Identity?
	const operator, version = range.op, range.version
	const major, minor, patch = version.major, version.minor, version.patch

	-- what is this even about bruh
	-- would love to be picky but i dont got time for that
	if operator == ">" or operator == ">=" then
		return nil
	elseif operator == "<" then
		return if version.prerelease then version else semver.new(major, minor, patch, "0")
	elseif operator == "=" or operator == "<=" then
		return successor(version)
	elseif operator == "~" or major == 0 then
		return semver.new(major, minor + 1, 0, "0")
	end

	return semver.new(major + 1, 0, 0, "0")
end

--[[
	AI generated implementations end
]]

const version_set = {}

function version_set.from_range(range: semver_range.Identity): Identity
	const lower_bound, upper_bound = lower_bound(range), upper_bound(range)

	if upper_bound and semver.compare(lower_bound, upper_bound) >= 0 then
		return interval_set.new(semver.older, semver.zero)
	end

	return interval_set.new(semver.older, semver.zero, lower_bound, upper_bound)
end

function version_set.contains(set: Identity, version: semver.Identity): boolean
	return interval_set.contains(set, version)
end

return table.freeze(version_set)
