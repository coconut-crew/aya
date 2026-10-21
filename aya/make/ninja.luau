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
	validations: { string }?,

	rule: string,

	variables: { [string]: string }?,
}

export type NinjaStatPool = {
	stat: "pool",

	name: string,
	depth: number,
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

export type NinjaStatSubninja = {
	stat: "subninja",

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
	| NinjaStatPool
	| NinjaStatRequiredVersion
	| NinjaStatRule
	| NinjaStatSubninja
	| NinjaStatVariableDecl

export type NinjaStaticFile = { version: NinjaStatRequiredVersion?, stmts: { NinjaStat } }
export type NinjaDyndepFile = { version: NinjaStatDyndepVersion, stmts: { NinjaStatBuild } }

const line_width = 78

const ninja = {}

function ninja.escape(input: string): string
	return (string.gsub(input, "[%$ :]", "$%0"))
end

const function format_value(value: string): string
	return (string.gsub(value, "^ +", function(spaces)
		return string.rep("$ ", #spaces)
	end))
end

const function print_variables(str_array: { string }, variables: { [string]: string })
	const keys: { string } = {}

	for key in variables do
		table.insert(keys, key)
	end

	table.sort(keys)

	for _, key in keys do
		table.insert(str_array, `  {key} = {format_value(variables[key])}\n`)
	end
end

const function append_paths(tokens: { string }, paths: { string })
	for _, input in paths do
		table.insert(tokens, ninja.escape(input))
	end
end

const function wrap(tokens: { string }): string
	const lines = {}
	local line = tokens[1]

	for index = 2, #tokens do
		const token = tokens[index]

		if #line + 1 + #token + 2 > line_width then
			table.insert(lines, line .. " $")
			line = "    " .. token
		else
			line ..= " " .. token
		end
	end

	table.insert(lines, line)

	return table.concat(lines, "\n") .. "\n"
end

function ninja.print_rule(stat: NinjaStatRule): string
	const str_array = {
		`rule {stat.name}\n`,
	}

	print_variables(str_array, stat.variables)

	return table.concat(str_array)
end

function ninja.print_pool(stat: NinjaStatPool): string
	return `pool {stat.name}\n  depth = {stat.depth}\n`
end

function ninja.print_default_target(stat: NinjaStatDefaultTarget): string
	assert(#stat.targets >= 1, "default needs at least 1 target")

	const tokens = { "default" }
	append_paths(tokens, stat.targets)

	return wrap(tokens)
end

function ninja.print_dyndep_version(stat: NinjaStatDyndepVersion): string
	return `ninja_dyndep_version = {format_value(stat.vers)}\n`
end

function ninja.print_include(stat: NinjaStatInclude): string
	return `include {ninja.escape(stat.file)}\n`
end

function ninja.print_subninja(stat: NinjaStatSubninja): string
	return `subninja {ninja.escape(stat.file)}\n`
end

function ninja.print_required_version(stat: NinjaStatRequiredVersion): string
	return `ninja_required_version = {format_value(stat.required_version)}\n`
end

function ninja.print_build(stat: NinjaStatBuild): string
	if #stat.outputs == 0 then
		error("ninja: build statement needs at least one output")
	end

	const tokens = { "build" }

	append_paths(tokens, stat.outputs)

	if stat.implicit_outputs and #stat.implicit_outputs > 0 then
		table.insert(tokens, "|")
		append_paths(tokens, stat.implicit_outputs)
	end

	tokens[#tokens] ..= ":"
	table.insert(tokens, stat.rule)

	append_paths(tokens, stat.dependencies)

	if stat.implicit_dependencies and #stat.implicit_dependencies > 0 then
		table.insert(tokens, "|")
		append_paths(tokens, stat.implicit_dependencies)
	end

	if stat.order_only_dependencies and #stat.order_only_dependencies > 0 then
		table.insert(tokens, "||")
		append_paths(tokens, stat.order_only_dependencies)
	end

	if stat.validations and #stat.validations > 0 then
		table.insert(tokens, "|@")
		append_paths(tokens, stat.validations)
	end

	const str_array = { wrap(tokens) }

	if stat.variables then
		print_variables(str_array, stat.variables)
	end

	return table.concat(str_array)
end

function ninja.print_variable_decl(stat: NinjaStatVariableDecl): string
	return `{stat.name} = {format_value(stat.value)}\n`
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
	elseif stat.stat == "pool" then
		return ninja.print_pool(stat)
	elseif stat.stat == "required_version" then
		return ninja.print_required_version(stat)
	elseif stat.stat == "rule" then
		return ninja.print_rule(stat)
	elseif stat.stat == "subninja" then
		return ninja.print_subninja(stat)
	elseif stat.stat == "variable_decl" then
		return ninja.print_variable_decl(stat)
	else
		return error("unreachable")
	end
end

const function print_stats(string_array: { string }, stats: { NinjaStat })
	for _, stat in stats do
		table.insert(string_array, ninja.print_stat(stat))

		-- blank line after multi-line blocks so the output stays readable
		if stat.stat == "build" or stat.stat == "rule" or stat.stat == "pool" then
			table.insert(string_array, "\n")
		end
	end
end

function ninja.print_file(file: NinjaStaticFile): string
	const string_array: { string } = {}

	if file.version then
		table.insert(string_array, ninja.print_required_version(file.version))
	end

	print_stats(string_array, file.stmts)

	return table.concat(string_array)
end

function ninja.print_dyndep_file(file: NinjaDyndepFile): string
	const string_array: { string } = {
		ninja.print_dyndep_version(file.version),
	}

	for _, stat in file.stmts do
		table.insert(string_array, ninja.print_build(stat))
		table.insert(string_array, "\n")
	end

	return table.concat(string_array)
end

return ninja
