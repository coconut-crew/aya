const manifest = require("@aya/manifest")
const semver = require("@aya/pkg/utils/semver")
const test = require("@std/test")

test.suite("manifest.parse", function(suite)
	suite:case("treats a bare version as a caret range", function(t)
		const parsed = manifest.parse([[
[dependencies]
log = { version = "0.1.0", github = "coconut-crew" }
]])

		const range = parsed.dependencies.log.version
		t.eq(range.op, "^")
		t.eq(range.version, semver.parse("0.1.0"))
	end)

	suite:case("keeps an explicit range operator", function(t)
		const parsed = manifest.parse([[
[dependencies]
exact = { version = "=1.2.0", github = "owner" }
open = { version = ">=2.0.0", github = "owner" }
]])

		t.eq(parsed.dependencies.exact.version.op, "=")
		t.eq(parsed.dependencies.open.version.op, ">=")
		t.eq(parsed.dependencies.open.version.version, semver.parse("2.0.0"))
	end)

	suite:case("sources a github dependency from the owner's repository", function(t)
		const parsed = manifest.parse([[
[dependencies]
bytenet = { version = "0.4.3", github = "ffrostfall" }
]])

		t.eq(parsed.dependencies.bytenet.source, {
			type = "git",
			remote = "https://github.com/ffrostfall/bytenet.git",
		})
	end)

	suite:case("parses an empty dependency table", function(t)
		const parsed = manifest.parse("[dependencies]\n")

		t.eq(parsed.dependencies, {})
	end)

	suite:case("parses a manifest without a dependency table", function(t)
		const parsed = manifest.parse("")

		t.eq(parsed.dependencies, {})
	end)

	suite:case("rejects a dependency entry that is not a table", function(t)
		t.throwsWith(
			"the dependencies entry must be a table",
			manifest.parse,
			[[dependencies = "log"]]
		)
	end)

	suite:case("stores dependencies under their global name", function(t)
		const parsed = manifest.parse([[
[dependencies]
Log = { version = "0.1.0", github = "coconut-crew" }
]])

		t.eq(parsed.dependencies.Log, nil)
		t.eq(parsed.dependencies.log.global_name, "log")
	end)

	suite:case("rejects a dependency without a source", function(t)
		t.throwsWith(
			"non-github dependencies are unsupported at this time",
			manifest.parse,
			[[
[dependencies]
log = { version = "0.1.0" }
]]
		)
	end)

	suite:case("rejects an invalid version", function(t)
		t.throws(
			manifest.parse,
			[[
[dependencies]
log = { version = "0.1", github = "coconut-crew" }
]]
		)
	end)
end)
