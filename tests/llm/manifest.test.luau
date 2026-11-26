const manifest = require("@src/manifest")
const semver = require("@src/pkg/utils/semver")
const semver_range = require("@src/pkg/utils/semver_range")
const test = require("@std/test")

test.suite("manifest.parse", function(suite)
	suite:case("treats a bare version as a caret range", function(t)
		const parsed = manifest.parse([[
dependencies:
  log: { version: "0.1.0", github: coconut-crew }
]])

		const range = parsed.dependencies.log.version
		t.eq(range.op, "^")
		t.eq(range.version, semver.parse("0.1.0"))
	end)

	suite:case("keeps an explicit range operator", function(t)
		const parsed = manifest.parse([[
dependencies:
  exact: { version: "=1.2.0", github: owner }
  open: { version: ">=2.0.0", github: owner }
]])

		t.eq(parsed.dependencies.exact.version.op, "=")
		t.eq(parsed.dependencies.open.version.op, ">=")
		t.eq(parsed.dependencies.open.version.version, semver.parse("2.0.0"))
	end)

	suite:case("sources a github dependency from the owner's repository", function(t)
		const parsed = manifest.parse([[
dependencies:
  bytenet: { version: "0.4.3", github: ffrostfall }
]])

		t.eq(parsed.dependencies.bytenet.source, {
			type = "git",
			remote = "https://github.com/ffrostfall/bytenet.git",
		})
	end)

	suite:case("parses an empty dependency table", function(t)
		const parsed = manifest.parse("dependencies: {}\n")

		t.eq(parsed.dependencies, {})
	end)

	suite:case("parses a manifest without a dependency table", function(t)
		const parsed = manifest.parse("")

		t.eq(parsed.dependencies, {})
	end)

	suite:case("rejects a dependency entry that is not a table", function(t)
		t.throws(manifest.parse, "dependencies: log")
	end)

	suite:case("stores dependencies under their global name", function(t)
		const parsed = manifest.parse([[
dependencies:
  Log: { version: "0.1.0", github: coconut-crew }
]])

		t.eq(parsed.dependencies.Log, nil)
		t.eq(parsed.dependencies.log.global_name, "log")
	end)

	suite:case("rejects a dependency without a source", function(t)
		t.throws(
			manifest.parse,
			[[
dependencies:
  log: { version: "0.1.0" }
]]
		)
	end)

	suite:case("rejects an invalid version", function(t)
		t.throws(
			manifest.parse,
			[[
dependencies:
  log: { version: "0.1", github: coconut-crew }
]]
		)
	end)

	suite:case("pins a github dependency to a rev and accepts any version from it", function(t)
		const parsed = manifest.parse([[
dependencies:
  log: { github: coconut-crew, rev: main }
]])

		t.eq(parsed.dependencies.log.source, {
			type = "git",
			remote = "https://github.com/coconut-crew/log.git",
			rev = "main",
		})
		t.eq(parsed.dependencies.log.version, semver_range.any)
	end)

	suite:case("keeps a version alongside a rev as a check on the pinned version", function(t)
		const parsed = manifest.parse([[
dependencies:
  log: { version: "1.2.0", github: coconut-crew, rev: main }
]])

		t.eq(parsed.dependencies.log.version.op, "^")
		t.eq(parsed.dependencies.log.source.rev, "main")
	end)

	suite:case("rejects a dependency with neither a version nor a rev", function(t)
		t.throws(
			manifest.parse,
			[[
dependencies:
  log: { github: coconut-crew }
]]
		)
	end)

	suite:case("reads the package version", function(t)
		const parsed = manifest.parse([[
package:
  version: "1.4.0"
]])

		t.eq(parsed.version, semver.parse("1.4.0"))
	end)

	suite:case("defaults the package version to 0.0.0", function(t)
		t.eq(manifest.parse("").version, semver.parse("0.0.0"))
	end)
end)
