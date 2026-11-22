const interval_set = require("@src/common/utils/interval_set")
const semver = require("@src/pkg/utils/semver")
const semver_range = require("@src/pkg/utils/semver_range")
const test = require("@std/test")
const version_set = require("@src/pkg/utils/version_set")

const function from_range(range: string): version_set.Identity
	return version_set.from_range(semver_range.parse(range))
end

const function allows(range: string, version: string): boolean
	return version_set.contains(from_range(range), semver.parse(version))
end

test.suite("version_set.from_range", function(suite)
	suite:case("tilde allows patch changes", function(t)
		t.that(allows("~1.2.3", "1.2.3"))
		t.that(allows("~1.2.3", "1.2.99"))
		t.never.that(allows("~1.2.3", "1.2.2"))
		t.never.that(allows("~1.2.3", "1.3.0"))
	end)

	suite:case("tilde allows patch changes when major and minor are 0", function(t)
		t.that(allows("~0.0.1", "0.0.5"))
		t.never.that(allows("~0.0.1", "0.1.0"))
	end)

	suite:case("caret allows minor and patch changes once major is at least 1", function(t)
		t.that(allows("^1.2.3", "1.2.3"))
		t.that(allows("^1.2.3", "1.99.0"))
		t.never.that(allows("^1.2.3", "1.2.2"))
		t.never.that(allows("^1.2.3", "2.0.0"))
	end)

	suite:case("caret allows only patch changes when major is 0", function(t)
		t.that(allows("^0.2.3", "0.2.3"))
		t.that(allows("^0.2.3", "0.2.99"))
		t.never.that(allows("^0.2.3", "0.2.2"))
		t.never.that(allows("^0.2.3", "0.3.0"))
	end)

	suite:case("caret allows patch changes when major and minor are 0", function(t)
		t.that(allows("^0.0.1", "0.0.1"))
		t.that(allows("^0.0.1", "0.0.9"))
		t.never.that(allows("^0.0.1", "0.0.0"))
		t.never.that(allows("^0.0.1", "0.1.0"))
	end)

	suite:case("equals allows only the exact version", function(t)
		t.that(allows("=1.2.3", "1.2.3"))
		t.never.that(allows("=1.2.3", "1.2.4"))
		t.never.that(allows("=1.2.3", "1.2.4-0"))
	end)

	suite:case("equals a prerelease allows only that prerelease", function(t)
		t.that(allows("=1.2.3-rc.1", "1.2.3-rc.1"))
		t.never.that(allows("=1.2.3-rc.1", "1.2.3-rc.1.0"))
		t.never.that(allows("=1.2.3-rc.1", "1.2.3"))
	end)

	suite:case("excludes prereleases of the upper bound", function(t)
		t.never.that(allows("^1.2.3", "2.0.0-alpha"))
		t.never.that(allows("~1.2.3", "1.3.0-0"))
		t.never.that(allows("^0.0.1", "0.1.0-alpha"))
	end)

	suite:case("excludes prereleases of the lower bound", function(t)
		t.never.that(allows("^1.2.3", "1.2.3-rc.1"))
	end)

	suite:case("allows prereleases strictly between the bounds", function(t)
		t.that(allows("^1.2.3", "1.5.0-beta"))
	end)

	suite:case("less than allows everything strictly below the version", function(t)
		t.that(allows("<1.2.3", "0.0.0"))
		t.that(allows("<1.2.3", "1.2.2"))
		t.never.that(allows("<1.2.3", "1.2.3"))
		t.never.that(allows("<1.2.3", "2.0.0"))
	end)

	suite:case("less than excludes prereleases of a release version", function(t)
		t.never.that(allows("<1.2.3", "1.2.3-alpha"))
	end)

	suite:case("less than a prerelease allows earlier prereleases of it", function(t)
		t.that(allows("<1.2.3-rc.2", "1.2.3-rc.1"))
		t.never.that(allows("<1.2.3-rc.2", "1.2.3-rc.2"))
	end)

	suite:case("less than zero allows nothing", function(t)
		t.that(interval_set.is_empty(from_range("<0.0.0")))
		t.that(interval_set.is_empty(from_range("<0.0.0-0")))
	end)

	suite:case("less than or equal allows the version and everything below it", function(t)
		t.that(allows("<=1.2.3", "0.0.0"))
		t.that(allows("<=1.2.3", "1.2.3"))
		t.never.that(allows("<=1.2.3", "1.2.4-0"))
		t.never.that(allows("<=1.2.3", "1.2.4"))
	end)

	suite:case("less than or equal a prerelease stops at that prerelease", function(t)
		t.that(allows("<=1.2.3-rc.1", "1.2.3-rc.1"))
		t.never.that(allows("<=1.2.3-rc.1", "1.2.3-rc.2"))
		t.never.that(allows("<=1.2.3-rc.1", "1.2.3"))
	end)

	suite:case("less than or equal zero allows only zero and its prereleases", function(t)
		t.that(allows("<=0.0.0", "0.0.0"))
		t.never.that(allows("<=0.0.0", "0.0.1-0"))
	end)

	suite:case("greater than allows everything strictly above the version", function(t)
		t.that(allows(">1.2.3", "1.2.4"))
		t.that(allows(">1.2.3", "99.0.0"))
		t.never.that(allows(">1.2.3", "1.2.3"))
		t.never.that(allows(">1.2.3", "1.2.2"))
	end)

	suite:case("greater than a prerelease allows its later prereleases and its release", function(t)
		t.that(allows(">1.2.3-rc.1", "1.2.3-rc.2"))
		t.that(allows(">1.2.3-rc.1", "1.2.3"))
		t.never.that(allows(">1.2.3-rc.1", "1.2.3-rc.1"))
	end)

	suite:case("greater than or equal allows the version and everything above it", function(t)
		t.that(allows(">=1.2.3", "1.2.3"))
		t.that(allows(">=1.2.3", "99.0.0"))
		t.never.that(allows(">=1.2.3", "1.2.2"))
		t.never.that(allows(">=1.2.3", "1.2.3-rc.1"))
	end)

	suite:case("greater than or equal zero allows every version", function(t)
		t.that(interval_set.is_full(from_range(">=0.0.0-0")))
	end)
end)

test.suite("version_set relations", function(suite)
	suite:case("a tilde range is a subset of the caret range on the same version", function(t)
		t.that(interval_set.is_subset(from_range("~1.2.3"), from_range("^1.2.3")))
		t.never.that(interval_set.is_subset(from_range("^1.2.3"), from_range("~1.2.3")))
	end)

	suite:case("caret ranges on different majors are disjoint", function(t)
		t.that(interval_set.is_disjoint(from_range("^1.0.0"), from_range("^2.0.0")))
	end)

	suite:case("a less than range is the complement of the greater than or equal range", function(t)
		const below, at_or_above = from_range("<1.2.3-rc.1"), from_range(">=1.2.3-rc.1")

		t.that(interval_set.is_disjoint(below, at_or_above))
		t.that(interval_set.is_full(interval_set.union(below, at_or_above)))
	end)
end)
