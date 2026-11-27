const fake = require("@src/pkg/sources/providers/fake")
const providers = require("@src/pkg/sources/providers")
const create_provider = require("@src/pkg/sources/create_provider")
const path = require("@std/path")
const semver = require("@src/pkg/utils/semver")
const semver_range = require("@src/pkg/utils/semver_range")
const test = require("@std/test")

test.suite("providers", function(suite)
	suite:beforeEach(function()
		table.clear(providers.list)
		table.clear(providers.pkgs)
		table.clear(fake.registry)
	end)

	suite:case("dispatches to the provider registered for the package's source type", function(t)
		providers.add_provider("fake", fake.provider)
		fake.registry.a = { ["1.0.0"] = {} }
		providers.add_package("a", { type = "fake" })

		const versions = providers.get_versions_async("a")

		t.eq(#versions, 1)
		t.eq(semver.print(versions[1]), "1.0.0")
	end)

	suite:case("dispatches get_dependencies_async to the package's provider", function(t)
		providers.add_provider("fake", fake.provider)
		fake.registry.a = { ["1.0.0"] = { b = semver_range.parse("^1.0.0") } }
		providers.add_package("a", { type = "fake" })

		const dependencies = providers.get_dependencies_async("a", semver.parse("1.0.0"))

		t.eq(semver_range.print(dependencies.b), "^1.0.0")
	end)

	suite:case("gives each provider the shared package sources", function(t)
		providers.add_provider("fake", fake.provider)
		fake.registry.a = { ["1.0.0"] = { b = semver_range.parse("^1.0.0") } }
		providers.add_package("a", { type = "fake" })

		providers.get_dependencies_async("a", semver.parse("1.0.0"))

		t.eq(providers.pkgs.b, { type = "fake" })
	end)

	suite:case("dispatches download_async with the version and destination", function(t)
		const calls: { { any } } = {}
		providers.add_provider(
			"recording",
			create_provider(function(_)
				return {
					download_async = function(name, version, at)
						table.insert(calls, { name, semver.print(version), path.format(at) })
					end,
					get_dependencies_async = function(): create_provider.DependencySet
						return {}
					end,
					get_versions_async = function(): { semver.Identity }
						return {}
					end,
				}
			end)
		)
		providers.add_package("a", { type = "recording" } :: any)

		providers.download_async("a", semver.parse("1.2.3"), "out/a")

		t.eq(calls, { { "a", "1.2.3", path.format("out/a") } })
	end)
	suite:case("rejects a package that has no source", function(t)
		providers.add_provider("fake", fake.provider)

		t.throwsWith(
			"package missing does not have a source",
			providers.get_versions_async,
			"missing"
		)
	end)

	suite:case("rejects a package whose source type has no provider", function(t)
		providers.add_package("a", { type = "git", remote = "https://github.com/someone/a.git" })

		t.throwsWith("no active provider named git", providers.get_versions_async, "a")
	end)
end)
