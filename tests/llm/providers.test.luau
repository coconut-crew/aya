const fake = require("@src/pkg/sources/providers/fake")
const providers = require("@src/pkg/sources/providers")
const semver = require("@src/pkg/utils/semver")
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

	suite:case("rejects a package that has no source", function(t)
		providers.add_provider("fake", fake.provider)

		t.throws(providers.get_versions_async, "missing")
	end)

	suite:case("rejects a package whose source type has no provider", function(t)
		providers.add_package("a", { type = "git", remote = "https://github.com/someone/a.git" })

		t.throws(providers.get_versions_async, "a")
	end)
end)
