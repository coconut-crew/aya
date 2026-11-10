const semver = require("@aya/common/semver")
const test = require("@std/test")

const function version(major: number, minor: number, patch: number): semver.Identity
	return {
		major = major,
		minor = minor,
		patch = patch,
		prerelease = false,
	}
end

test.suite("semver.parse", function(suite)
	suite:case("parses a release version with no prerelease", function(t)
		t.eq(semver.parse("1.20.3"), version(1, 20, 3))
	end)

	suite:case("parses a prerelease after a dash", function(t)
		t.eq(semver.parse("0.4.0-alpha.1").prerelease, "alpha.1")
	end)

	suite:case("keeps hyphens inside the prerelease", function(t)
		t.eq(semver.parse("1.0.0-rc-2").prerelease, "rc-2")
	end)

	suite:case("ignores build metadata", function(t)
		t.eq(semver.parse("1.2.3+build.5"), version(1, 2, 3))
	end)

	suite:case("separates the prerelease from build metadata", function(t)
		t.eq(semver.parse("1.2.3-beta+exp.sha.5114f85").prerelease, "beta")
	end)

	suite:case("rejects a version missing the patch number", function(t)
		t.throws(semver.parse, "1.2")
	end)

	suite:case("rejects a prerelease without a dash", function(t)
		t.throws(semver.parse, "1.2.3abc")
	end)

	suite:case("rejects a dash without a prerelease", function(t)
		t.throws(semver.parse, "1.2.3-")
	end)

	suite:case("rejects text before the version", function(t)
		t.throws(semver.parse, "version 1.2.3")
	end)
end)

test.suite("semver.compatible", function(suite)
	suite:case("accepts minor and patch differences once major is at least 1", function(t)
		t.that(semver.compatible(version(1, 2, 3), version(1, 7, 0)))
	end)

	suite:case("rejects different major versions", function(t)
		t.never.that(semver.compatible(version(1, 9, 9), version(2, 0, 0)))
	end)

	suite:case("rejects different minor versions when major is 0", function(t)
		t.never.that(semver.compatible(version(0, 1, 0), version(0, 2, 0)))
	end)

	suite:case("accepts patch differences when major is 0", function(t)
		t.that(semver.compatible(version(0, 3, 1), version(0, 3, 4)))
	end)
end)
