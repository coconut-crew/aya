const bir_emit = require("@src/build/bir/bir_emit")
const bir_types = require("@src/build/bir/bir_types")
const test = require("@std/test")

const function compile_stat(src: string, dst: string): bir_types.BirTransformLuauObject
	return {
		stat = "transform",
		src = src,
		dst = dst,
		vars = {},
	}
end

const function link_stat(dir: string, link_count: number): bir_types.BirLinkCrates
	const links = {}

	for index = 1, link_count do
		table.insert(links, {
			src = `{dir}/src/link_{index}.luau`,
			link_location = `{dir}/links/link_{index}.luau`,
		})
	end

	return {
		stat = "link_crates",
		dir = dir,
		links = links,
	}
end

-- { [rule name]: true }
const function declared_rules(output: string): { [string]: true }
	const rules = {}

	for _, line in string.split(output, "\n") do
		if string.sub(line, 1, 5) == "rule " then
			rules[string.sub(line, 6)] = true
		end
	end

	return rules
end

const function find_line(output: string, needle: string): string?
	for _, line in string.split(output, "\n") do
		if string.find(line, needle, 1, true) then
			return line
		end
	end

	return nil
end

const function used_rules(output: string): { string }
	const rules = {}

	for _, line in string.split(output, "\n") do
		if string.sub(line, 1, 6) ~= "build " then
			continue
		end

		const colon = string.find(line, ": ", 1, true)
		assert(colon, "build line has no rule")

		table.insert(rules, string.split(string.sub(line, colon + 2), " ")[1])
	end

	return rules
end

test.suite("bir_emit.walk", function(suite)
	suite:case("emits a compile build from the source to the destination", function(t)
		const output = bir_emit.walk({ compile_stat("src/main.luau", "out/main.luau") })

		t.strContains(output, "build out/main.luau: transform src/main.luau\n")
	end)

	suite:case("carries compile variables onto the build statement", function(t)
		const stat = compile_stat("src/main.luau", "out/main.luau")
		stat.vars = { optimize = "2" }

		const output = bir_emit.walk({ stat })

		t.strContains(output, "  optimize = 2\n")
	end)

	suite:case("emits one build per compile stat", function(t)
		const output = bir_emit.walk({
			compile_stat("src/a.luau", "out/a.luau"),
			compile_stat("src/b.luau", "out/b.luau"),
			compile_stat("src/c.luau", "out/c.luau"),
		})

		t.strContains(output, ": transform ", 3)
	end)

	suite:case("escapes special characters in paths exactly once", function(t)
		const output = bir_emit.walk({ compile_stat("my crate/main.luau", "out/main.luau") })

		t.strContains(output, "my$ crate")
		t.strNotContains(output, "$$")
	end)

	suite:case("emits one linkers build per link pair", function(t)
		const output = bir_emit.walk({ link_stat("crates/foo", 2) })

		t.strContains(output, ": linkers ", 2)
	end)

	suite:case("marks the crate config as an implicit output of the configure build", function(t)
		const output = bir_emit.walk({ link_stat("crates/foo", 0) })

		const configure_line = find_line(output, ": configure")
		assert(configure_line, "no configure build in output")

		-- the joined path's separator is platform specific, so only check the file name
		t.strContains(configure_line, " | ")
		t.strContains(configure_line, ".config.luau")
	end)

	suite:case("regenerates build.ninja as a generator build even with no stats", function(t)
		const output = bir_emit.walk({})

		const configure_line = find_line(output, ": configure")
		assert(configure_line, "no configure build in output")

		const first_output = string.split(configure_line, " ")[2]
		t.that(
			first_output == "build.ninja" or first_output == "build.ninja:",
			`configure build outputs {first_output}, not build.ninja`
		)
		-- without generator, `ninja -t clean` would delete build.ninja
		t.strContains(output, "  generator = 1\n")
	end)

	suite:case("declares every rule a build statement uses", function(t)
		const output = bir_emit.walk({
			compile_stat("src/main.luau", "out/main.luau"),
			link_stat("crates/foo", 1),
		})

		const declared = declared_rules(output)

		for _, rule in used_rules(output) do
			t.that(declared[rule], `rule {rule} is used but never declared`)
		end
	end)
end)
