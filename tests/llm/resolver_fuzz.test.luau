const fake = require("@src/pkg/sources/providers/fake")
const json = require("@vendor/json")
const process = require("@std/process")
const providers = require("@src/pkg/sources/providers")
const resolver = require("@src/pkg/resolver")
const semver = require("@src/pkg/utils/semver")
const semver_range = require("@src/pkg/utils/semver_range")
const test = require("@std/test")
const version_set = require("@src/pkg/utils/version_set")

-- { [package name]: { [version]: { [dependency name]: range string } } }
type Registry = { [string]: { [string]: { [string]: string } } }

-- { [package name]: range string }
type Roots = { [string]: string }

-- { [package name]: version string }
type Assignment = { [string]: string }

const NAMES = { "a", "b", "c", "d", "e" }
const OPERATORS = { "^", "~", "=", "<", ">", "<=", ">=" }
const DEPENDENCY_CHANCE = 0.3

-- override with AYA_FUZZ_SEED / AYA_FUZZ_ITERATIONS for longer runs
const DEFAULT_SEED = 1
const DEFAULT_ITERATIONS = 200

const function env_number(name: string, default: number): number
	return tonumber(process.env[name] or "") or default
end

const function random_version(): string
	return `{math.random(0, 2)}.{math.random(0, 2)}.{math.random(0, 1)}`
end

const function random_range(): string
	return OPERATORS[math.random(#OPERATORS)] .. random_version()
end

const function random_registry(): (Registry, { string })
	const names = table.move(NAMES, 1, math.random(2, #NAMES), 1, {})
	const registry: Registry = {}

	for _, name in names do
		const versions = {}

		for _ = 1, math.random(1, 3) do
			const dependencies = {}
			for _, other in names do
				if other ~= name and math.random() < DEPENDENCY_CHANCE then
					dependencies[other] = random_range()
				end
			end

			-- a repeated version overwrites the earlier one, which only lowers the version count
			versions[random_version()] = dependencies
		end

		registry[name] = versions
	end

	return registry, names
end

const function random_roots(names: { string }): Roots
	const roots: Roots = {}
	for _ = 1, math.random(1, 2) do
		roots[names[math.random(#names)]] = random_range()
	end

	return roots
end

const function use_registry(registry: Registry)
	table.clear(providers.pkgs)
	table.clear(fake.registry)

	providers.add_provider("fake", fake.provider)

	for name, versions in registry do
		const entry: { [string]: resolver.Ranges } = {}
		for version, dependencies in versions do
			const ranges: resolver.Ranges = {}
			for dependency, range in dependencies do
				ranges[dependency] = semver_range.parse(range)
			end

			entry[version] = ranges
		end

		fake.registry[name] = entry
		providers.add_package(name, { type = "fake" })
	end
end

const function satisfies(version: string, range: string): boolean
	return version_set.contains(
		version_set.from_range(semver_range.parse(range)),
		semver.parse(version)
	)
end

-- why the assignment is not a valid, minimal resolution, or nil when it is one
const function find_problem(registry: Registry, roots: Roots, assignment: Assignment): string?
	const reached: { [string]: true } = {}
	const pending: { string } = {}

	for name, range in roots do
		const version = assignment[name]
		if not version or not satisfies(version, range) then
			return `root needs {name} {range}, got {version or "nothing"}`
		end

		table.insert(pending, name)
	end

	while #pending > 0 do
		const name = table.remove(pending) :: string
		if reached[name] then
			continue
		end
		reached[name] = true

		const version = assignment[name]
		const dependencies = registry[name][version]
		if not dependencies then
			return `{name}@{version} is not in the registry`
		end

		for dependency, range in dependencies do
			const selected = assignment[dependency]
			if not selected or not satisfies(selected, range) then
				return `{name}@{version} needs {dependency} {range}, got {selected or "nothing"}`
			end

			table.insert(pending, dependency)
		end
	end

	for name, version in assignment do
		if not reached[name] then
			return `{name}@{version} is selected but nothing requires it`
		end
	end

	return nil
end

-- tries every combination of a version (or nothing) for each package
const function has_solution(registry: Registry, names: { string }, roots: Roots): boolean
	const assignment: Assignment = {}

	const function search(index: number): boolean
		if index > #names then
			return find_problem(registry, roots, assignment) == nil
		end

		const name = names[index]
		assignment[name] = nil
		if search(index + 1) then
			return true
		end

		for version in registry[name] do
			assignment[name] = version
			if search(index + 1) then
				return true
			end
		end

		assignment[name] = nil
		return false
	end

	return search(1)
end

-- how the resolver disagrees with the brute-force search, or nil when it agrees
const function check_case(registry: Registry, names: { string }, roots: Roots): string?
	use_registry(registry)

	const parsed_roots: resolver.Ranges = {}
	for name, range in roots do
		parsed_roots[name] = semver_range.parse(range)
	end

	-- the explicit nil fills solve's optional `locked`, which pcall's typing treats as required
	const ok, result = pcall(resolver.solve, parsed_roots, nil)
	if not ok then
		const message = tostring(result)
		if not string.find(message, "version conflict", 1, true) then
			return `resolver crashed: {message}`
		end

		if has_solution(registry, names, roots) then
			return `resolver reported a conflict, but a solution exists: {message}`
		end

		return nil
	end

	const assignment: Assignment = {}
	for name, version in result do
		assignment[name] = semver.print(version)
	end

	const problem = find_problem(registry, roots, assignment)
	if problem then
		return `resolver returned an invalid resolution: {problem}`
	end

	return nil
end

test.suite("resolver fuzz", function(suite)
	suite:case("agrees with a brute-force search on random registries", function(t)
		const seed = env_number("AYA_FUZZ_SEED", DEFAULT_SEED)
		const iterations = env_number("AYA_FUZZ_ITERATIONS", DEFAULT_ITERATIONS)
		math.randomseed(seed)

		for iteration = 1, iterations do
			const registry, names = random_registry()
			const roots = random_roots(names)

			const failure = check_case(registry, names, roots)
			if failure then
				-- json.serialize wants json.Value, which the nested string tables can't be passed as
				const registry_text = json.serialize(registry :: any)
				const roots_text = json.serialize(roots :: any)

				t.eq(
					failure,
					nil,
					`{failure}\nseed {seed}, iteration {iteration}\nroots: {roots_text}\nregistry: {registry_text}`
				)
				return
			end
		end
	end)
end)
