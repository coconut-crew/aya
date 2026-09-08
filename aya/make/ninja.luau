const path = require("@std/path")

export type NinjaStatRule = {
	stat: "rule",

	name: string,
	variables: { command: string, [string]: string },
}

export type NinjaStatBuild = {
	stat: "build",

	outputs: { string },
	implicit_outputs: { string }?,

	dependencies: { string },
	implicit_dependencies: { string }?,
	order_only_dependencies: { string }?,

	rule: string,

	variables: { [string]: string }?,
}

export type NinjaStatDyndepVersion = {
	stat: "dyndep_version",

	vers: string,
}

export type NinjaStatVariableDecl = {
	stat: "variable_decl",

	name: string,
	value: string,
}

export type NinjaStatDefaultTarget = {
	stat: "default_target",

	targets: { string },
}

export type NinjaStatInclude = {
	stat: "include",

	file: string,
}

export type NinjaStatRequiredVersion = {
	stat: "required_version",

	required_version: string,
}

export type NinjaStat =
	| NinjaStatBuild
	| NinjaStatDefaultTarget
	| NinjaStatDyndepVersion
	| NinjaStatInclude
	| NinjaStatRequiredVersion
	| NinjaStatRule
	| NinjaStatVariableDecl

export type NinjaFile = { NinjaStat }

local ninja = {}

const function escape(input: string)
	return string.gsub(input, ":", "$:")
end

function ninja.print_rule(stat: NinjaStatRule): string
	const str_array = {
		`rule {stat.name}\n`,
	}

	for key, value in stat.variables do
		table.insert(str_array, `  {key} = {value}\n`)
	end

	return table.concat(str_array)
end

function ninja.print_default_target(stat: NinjaStatDefaultTarget): string
	return `default {table.concat(stat.targets, " ")}\n`
end

function ninja.print_dyndep_version(stat: NinjaStatDyndepVersion): string
	return `ninja_dyndep_version = {stat.vers}\n`
end

function ninja.print_include(stat: NinjaStatInclude): string
	return `include {stat.file}\n`
end

function ninja.print_required_version(stat: NinjaStatRequiredVersion): string
	return `ninja_required_version = {stat.required_version}\n`
end

function ninja.print_build(stat: NinjaStatBuild): string
	const str_array = {}

	table.insert(str_array, `build {escape(table.concat(stat.outputs, " "))}`)

	if stat.implicit_outputs then
		table.insert(str_array, ` | {escape(table.concat(stat.implicit_outputs, " "))}`)
	end

	table.insert(str_array, `: {stat.rule} {escape(table.concat(stat.dependencies, " "))}`)

	if stat.implicit_dependencies then
		table.insert(str_array, ` | {escape(table.concat(stat.implicit_dependencies, " "))}`)
	end

	if stat.order_only_dependencies then
		table.insert(str_array, ` || {escape(table.concat(stat.order_only_dependencies, " "))}`)
	end

	table.insert(str_array, "\n")

	if stat.variables then
		for key, value in stat.variables do
			table.insert(str_array, `  {key} = {value}\n`)
		end
	end

	return table.concat(str_array) .. "\n"
end

function ninja.print_variable_decl(stat: NinjaStatVariableDecl): string
	return `{stat.name} = {stat.value}\n`
end

function ninja.print_stat(stat: NinjaStat): string
	if stat.stat == "build" then
		return ninja.print_build(stat)
	elseif stat.stat == "default_target" then
		return ninja.print_default_target(stat)
	elseif stat.stat == "dyndep_version" then
		return ninja.print_dyndep_version(stat)
	elseif stat.stat == "include" then
		return ninja.print_include(stat)
	elseif stat.stat == "required_version" then
		return ninja.print_required_version(stat)
	elseif stat.stat == "rule" then
		return ninja.print_rule(stat)
	elseif stat.stat == "variable_decl" then
		return ninja.print_variable_decl(stat)
	else
		return error("unreachable")
	end
end

function ninja.print_file(stat_array: { NinjaStat }): string
	const string_array: { string } = {}

	for _, stat in stat_array do
		table.insert(string_array, (ninja.print_stat(stat)))
	end

	return table.concat(string_array)
end

function ninja.escape_path(input: path.Path): string
	return (string.gsub(path.format(input), "C:", "C$:"))
end

return ninja
