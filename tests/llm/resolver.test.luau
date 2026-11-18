const fake = require("@aya/pkg/sources/providers/fake")
const providers = require("@aya/pkg/sources/providers")
const resolver = require("@aya/pkg/resolver")
const semver = require("@aya/pkg/utils/semver")
const semver_range = require("@aya/pkg/utils/semver_range")
const test = require("@std/test")

-- { [package name]: range string }
const function ranges(spec: { [string]: string }): resolver.Ranges
	const result: resolver.Ranges = {}
	for name, range in spec do
		result[name] = semver_range.parse(range)
	end

	return result
end

-- replaces every registered package with the fake ones in the spec
-- packages in `registered` get a source up front, defaulting to every package in the spec
-- { [package name]: { [version]: { [dependency name]: range string } } }
const function use_registry(
	spec: { [string]: { [string]: { [string]: string } } },
	registered: { string }?
)
	table.clear(providers.pkgs)
	table.clear(fake.registry)

	providers.add_provider("fake", fake.provider)

	for name, versions in spec do
		const entry: { [string]: resolver.Ranges } = {}
		for version, dependencies in versions do
			entry[version] = ranges(dependencies)
		end

		fake.registry[name] = entry
		if registered == nil or table.find(registered, name) then
			providers.add_package(name, { type = "fake" })
		end
	end
end

const function version_in(resolution: resolver.Resolution, name: string): string?
	const selected = resolution[name]
	return if selected then semver.print(selected) else nil
end

const function solve_error(roots: resolver.Ranges): string
	const ok, err = pcall(resolver.solve, roots, nil)
	assert(not ok, "expected solve to fail")
	return tostring(err)
end

test.suite("resolver.solve", function(suite)
	suite:case("selects the newest version satisfying the root requirement", function(t)
		use_registry({
			a = { ["2.0.0"] = {}, ["1.3.0"] = {}, ["1.0.0"] = {} },
		})

		const resolution = resolver.solve(ranges({ a = "^1.0.0" }))

		t.eq(version_in(resolution, "a"), "1.3.0")
	end)

	suite:case("resolves transitive dependencies", function(t)
		use_registry({
			a = { ["1.0.0"] = { b = "^1.0.0" } },
			b = { ["1.1.0"] = { c = "^0.2.0" } },
			c = { ["0.2.5"] = {}, ["0.2.1"] = {} },
		})

		const resolution = resolver.solve(ranges({ a = "^1.0.0" }))

		t.eq(version_in(resolution, "b"), "1.1.0")
		t.eq(version_in(resolution, "c"), "0.2.5")
	end)

	suite:case("rejects two major versions of one package", function(t)
		use_registry({
			a = { ["1.0.0"] = { b = "^2.0.0" } },
			b = { ["2.1.0"] = {}, ["1.4.0"] = {} },
		})

		const message = solve_error(ranges({ a = "^1.0.0", b = "^1.0.0" }))

		t.strContains(message, "version conflict for 'b'")
		t.strContains(message, "^1.0.0  (required by root)")
		t.strContains(message, "^2.0.0  (required by a@1.0.0)")
	end)

	suite:case("rejects two 0.x minor versions of one package", function(t)
		use_registry({
			a = { ["1.0.0"] = { b = "^0.4.0" } },
			b = { ["0.4.1"] = {}, ["0.3.2"] = {} },
		})

		const message = solve_error(ranges({ a = "^1.0.0", b = "^0.3.0" }))

		t.strContains(message, "version conflict for 'b'")
	end)

	suite:case("narrows an open range by a caret range on the same package", function(t)
		use_registry({
			a = { ["2.1.0"] = {}, ["1.0.0"] = {} },
			b = { ["1.0.0"] = { a = "^1.0.0" } },
		})

		const resolution = resolver.solve(ranges({ a = ">=1.0.0", b = "^1.0.0" }))

		t.eq(version_in(resolution, "a"), "1.0.0")
	end)

	suite:case(
		"falls back to an older version when the newest has a conflicting dependency",
		function(t)
			use_registry({
				a = { ["1.1.0"] = { c = "=1.0.0" }, ["1.0.0"] = {} },
				c = { ["1.2.0"] = {}, ["1.0.0"] = {} },
			})

			const resolution = resolver.solve(ranges({ a = "^1.0.0", c = "^1.1.0" }))

			t.eq(version_in(resolution, "a"), "1.0.0")
			t.eq(version_in(resolution, "c"), "1.2.0")
		end
	)

	suite:case("revisits an earlier selection when a later dependency rules it out", function(t)
		-- b has more candidates than a, so a is selected before b's constraint on it is known
		use_registry({
			a = { ["1.1.0"] = {}, ["1.0.0"] = {} },
			b = {
				["1.2.0"] = { a = "<1.1.0" },
				["1.1.0"] = { a = "<1.1.0" },
				["1.0.0"] = { a = "<1.1.0" },
			},
		})

		const resolution = resolver.solve(ranges({ a = "^1.0.0", b = "^1.0.0" }))

		t.eq(version_in(resolution, "a"), "1.0.0")
		t.eq(version_in(resolution, "b"), "1.2.0")
	end)

	suite:case("prefers the locked version over newer satisfying versions", function(t)
		use_registry({
			a = { ["1.2.0"] = {}, ["1.1.0"] = {}, ["1.0.0"] = {} },
		})

		const resolution = resolver.solve(ranges({ a = "^1.0.0" }), { ["a@1.1.0"] = true })

		t.eq(version_in(resolution, "a"), "1.1.0")
	end)

	suite:case("ignores a locked version outside the required range", function(t)
		use_registry({
			a = { ["2.0.0"] = {}, ["1.2.0"] = {}, ["1.0.0"] = {} },
		})

		const resolution = resolver.solve(ranges({ a = "^1.0.0" }), { ["a@2.0.0"] = true })

		t.eq(version_in(resolution, "a"), "1.2.0")
	end)

	suite:case("rejects a requirement on a package with no registered source", function(t)
		use_registry({})

		t.throws(resolver.solve, ranges({ missing = "^1.0.0" }), nil)
	end)

	suite:case("reports every conflicting requirement and who required it", function(t)
		use_registry({
			a = { ["1.0.0"] = { c = "=1.0.0" } },
			b = { ["1.0.0"] = { c = "=1.1.0" } },
			c = { ["1.1.0"] = {}, ["1.0.0"] = {} },
		})

		const message = solve_error(ranges({ a = "^1.0.0", b = "^1.0.0" }))

		t.strContains(message, "version conflict for 'c'")
		t.strContains(message, "=1.0.0  (required by a@1.0.0)")
		t.strContains(message, "=1.1.0  (required by b@1.0.0)")
	end)

	suite:case("resolves dependencies whose source is only known from their dependent", function(t)
		use_registry({
			a = { ["1.0.0"] = { b = "^1.0.0" } },
			b = { ["1.0.0"] = { c = "^1.0.0" } },
			c = { ["1.2.0"] = {}, ["1.0.0"] = {} },
		}, { "a" })

		const resolution = resolver.solve(ranges({ a = "^1.0.0" }))

		t.eq(version_in(resolution, "b"), "1.0.0")
		t.eq(version_in(resolution, "c"), "1.2.0")
	end)

	suite:case("applies every dependent's range to a dependency discovered earlier", function(t)
		use_registry({
			a = { ["1.0.0"] = { b = "^1.0.0" } },
			c = { ["1.0.0"] = { b = "=1.0.0" } },
			b = { ["1.1.0"] = {}, ["1.0.0"] = {} },
		}, { "a", "c" })

		const resolution = resolver.solve(ranges({ a = "^1.0.0", c = "^1.0.0" }))

		t.eq(version_in(resolution, "b"), "1.0.0")
	end)

	suite:case("omits dependencies only required by an abandoned candidate", function(t)
		use_registry({
			a = {
				["1.1.0"] = { c = "=1.0.0", x = "^1.0.0" },
				["1.0.0"] = {},
			},
			c = { ["1.2.0"] = {}, ["1.0.0"] = {} },
			x = { ["1.0.0"] = {} },
		}, { "a", "c" })

		const resolution = resolver.solve(ranges({ a = "^1.0.0", c = "^1.1.0" }))

		t.eq(version_in(resolution, "a"), "1.0.0")
		t.eq(version_in(resolution, "x"), nil)
	end)
end)
