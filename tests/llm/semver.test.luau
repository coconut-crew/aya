const semver = require("@src/pkg/utils/semver")
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
	suite:case("rejects empty prerelease identifiers", function(t)
		t.throws(semver.parse, "1.0.0-a..b")
		t.throws(semver.parse, "1.0.0-.a")
		t.throws(semver.parse, "1.0.0-a.")
	end)

	suite:case("accepts alphanumeric prerelease identifiers that start with zero", function(t)
		t.eq(semver.print(semver.parse("1.0.0-01e5")), "1.0.0-01e5")
	end)

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

	suite:case("rejects text after the version", function(t)
		t.throws(semver.parse, "1.2.3 ")
		t.throws(semver.parse, "1.2.3-beta!")
		t.throws(semver.parse, "1.2.3+build!")
	end)
	suite:case("accepts zero as a version number", function(t)
		t.eq(semver.parse("0.0.0"), version(0, 0, 0))
	end)

	suite:case("rejects leading zeros in the major, minor or patch number", function(t)
		t.throws(semver.parse, "01.2.3")
		t.throws(semver.parse, "1.02.3")
		t.throws(semver.parse, "1.2.03")
	end)

	suite:case("rejects leading zeros in a numeric prerelease identifier", function(t)
		t.throws(semver.parse, "1.2.3-alpha.01")
	end)

	suite:case("allows leading zeros in an alphanumeric prerelease identifier", function(t)
		t.eq(semver.parse("1.2.3-0abc").prerelease, "0abc")
	end)
end)

test.suite("semver.order", function(suite)
	const function older(left: string, right: string): boolean
		return semver.compare(semver.parse(left), semver.parse(right)) < 0
	end

	suite:case("orders by major, then minor, then patch", function(t)
		t.that(older("1.9.9", "2.0.0"))
		t.that(older("1.2.9", "1.10.0"))
		t.that(older("1.2.3", "1.2.4"))
	end)

	suite:case("puts a prerelease before its release", function(t)
		t.that(older("1.0.0-rc.1", "1.0.0"))
		t.that(older("1.0.0", "1.0.1-0"))
	end)

	suite:case("follows the semver spec's prerelease precedence example", function(t)
		const ordered = { "alpha", "alpha.1", "alpha.beta", "beta", "beta.2", "beta.11", "rc.1" }
		for index = 1, #ordered - 1 do
			t.that(older(`1.0.0-{ordered[index]}`, `1.0.0-{ordered[index + 1]}`))
		end
	end)

	suite:case("ignores build metadata", function(t)
		t.eq(semver.compare(semver.parse("1.0.0+a"), semver.parse("1.0.0+b")), 0)
	end)

	suite:case("compare reports whether the left version is newer", function(t)
		t.that(semver.newer(version(2, 0, 0), version(1, 0, 0)))
		t.never.that(semver.newer(version(1, 0, 0), version(1, 0, 0)))
	end)

	suite:case("older reports whether the left version is strictly older", function(t)
		t.that(semver.older(version(1, 0, 0), version(2, 0, 0)))
		t.never.that(semver.older(version(1, 0, 0), version(1, 0, 0)))
		t.never.that(semver.older(version(2, 0, 0), version(1, 0, 0)))
	end)end)

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

test.suite("semver.new", function(suite)
	suite:case("builds a release when no prerelease is given", function(t)
		t.eq(semver.new(1, 2, 3), version(1, 2, 3))
	end)

	suite:case("keeps the prerelease it is given", function(t)
		t.eq(semver.new(1, 2, 3, "rc.1").prerelease, "rc.1")
	end)
end)
