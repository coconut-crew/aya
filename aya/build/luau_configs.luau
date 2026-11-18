const path = require("@std/path")

export type ConfigTable = {
	aliases: {
		[string]: path.Pathlike,
	},

	language_mode: "strict" | "nonstrict" | "nocheck",

	lint: { [string]: boolean },
}

const function escape(str: string)
	return string.format("%q", str)
end

const function print_language_mode(mode: "strict" | "nonstrict" | "nocheck"): string
	return `languagemode = "{mode}",`
end

const function print_aliases(alias_list: { [string]: path.Pathlike }): string
	const printed_aliases = {}

	for alias, location in alias_list do
		table.insert(printed_aliases, `[{escape(alias)}] = {escape(path.format(location))},`)
	end

	table.sort(printed_aliases)

	return "aliases = {\n" .. table.concat(printed_aliases, "\n") .. "\n},"
end

const luau_configs = {}

function luau_configs.serialize(tbl: ConfigTable): string
	return `return \{\nluau = \{\n{print_language_mode(tbl.language_mode)}\n{print_aliases(
		tbl.aliases
	)}\n}\n}`
end

return table.freeze(luau_configs)
