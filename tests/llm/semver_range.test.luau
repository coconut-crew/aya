const semver = require("@src/pkg/utils/semver")
const semver_range = require("@src/pkg/utils/semver_range")
const test = require("@std/test")

test.suite("semver_range.parse", function(suite)
	suite:case("reads the operator and the version after it", function(t)
		const range = semver_range.parse("~1.2.3")

		t.eq(range.op, "~")
		t.eq(range.version, semver.parse("1.2.3"))
	end)

	suite:case("reads a two character operator", function(t)
		const range = semver_range.parse(">=1.2.3-rc.1")

		t.eq(range.op, ">=")
		t.eq(range.version, semver.parse("1.2.3-rc.1"))
	end)

	suite:case("rejects a version without an operator", function(t)
		t.throws(semver_range.parse, "1.2.3")
	end)

	suite:case("rejects an empty string", function(t)
		t.throws(semver_range.parse, "")
	end)

	suite:case("rejects an unknown two character operator", function(t)
		t.throws(semver_range.parse, "^=1.2.3")
		t.throws(semver_range.parse, "==1.2.3")
	end)

	suite:case("rejects an invalid version after the operator", function(t)
		t.throws(semver_range.parse, "^1.2")
	end)
end)

test.suite("semver_range.print", function(suite)
	suite:case("prints back to the text it was parsed from", function(t)
		for _, text in { "^0.2.3-beta.1", "~1.2.3", "<=1.0.0", ">2.0.0-rc.1" } do
			t.eq(semver_range.print(semver_range.parse(text)), text)
		end
	end)
end)
