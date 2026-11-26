const luau = require("@std/luau")
const luau_configs = require("@src/build/luau_configs")
const path = require("@std/path")
const test = require("@std/test")

-- runs the serialized config with no globals, the way luau tooling reads a .config.luau
const function evaluate(config: luau_configs.ConfigTable): any
	const source = luau_configs.serialize(config)
	return luau.load(luau.compile(source), "config", {})()
end

const function config_with(aliases: { [string]: path.Pathlike }): luau_configs.ConfigTable
	return {
		aliases = aliases,
		language_mode = "strict",
		lint = {},
	}
end

test.suite("luau_configs.serialize", function(suite)
	suite:case("writes each language mode as a string", function(t)
		for _, mode in
			{ "strict", "nonstrict", "nocheck" } :: { "strict" | "nonstrict" | "nocheck" }
		do
			const config = config_with({})
			config.language_mode = mode

			t.eq(evaluate(config).luau.languagemode, mode)
		end
	end)

	suite:case("writes every alias with its path", function(t)
		const result = evaluate(config_with({
			std = "lute/std",
			pkg = path.parse("pkgs/links"),
		}))

		t.eq(result.luau.aliases, {
			std = path.format("lute/std"),
			pkg = path.format(path.parse("pkgs/links")),
		})
	end)

	suite:case("writes aliases in sorted order so output is reproducible", function(t)
		const output = luau_configs.serialize(config_with({ zeta = "z", alpha = "a", mid = "m" }))

		const alpha = string.find(output, "alpha", 1, true)
		const mid = string.find(output, "mid", 1, true)
		const zeta = string.find(output, "zeta", 1, true)
		assert(alpha and mid and zeta, "every alias is written")

		t.that(alpha < mid and mid < zeta, "aliases are not sorted")
	end)
	suite:case("writes an empty alias table when there are no aliases", function(t)
		t.eq(evaluate(config_with({})).luau.aliases, {})
	end)

	suite:case("keeps alias names that are not identifiers", function(t)
		const result = evaluate(config_with({ ["my-alias"] = "vendor" }))

		t.eq(result.luau.aliases["my-alias"], "vendor")
	end)

	suite:case("keeps backslashes in alias paths", function(t)
		const result = evaluate(config_with({ pkg = "pkgs\\links" }))

		t.eq(result.luau.aliases.pkg, "pkgs\\links")
	end)
end)
