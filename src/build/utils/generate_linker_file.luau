const fs = require("@std/fs")
const path = require("@std/path")
const query = require("@std/syntax/query")
const syntax = require("@std/syntax")
const printer = require("@std/syntax/printer")
const types = require("@std/syntax/types")

-- prints a node without the whitespace around it
const function print_trimmed(node: types.CstNode): string
	return string.match(printer.printNode(node), "^%s*(.-)%s*$") :: string
end

const function render_generic_array(
	file_contents: { string },
	generic_default_pairs: { string | false },
	render_defaults: boolean
)
	if #generic_default_pairs == 0 then
		return
	end

	table.insert(file_contents, "<")

	for i = 1, #generic_default_pairs, 2 do
		const generic_arg, default_arg = generic_default_pairs[i], generic_default_pairs[i + 1]

		table.insert(file_contents, tostring(generic_arg))

		if default_arg and render_defaults then
			table.insert(file_contents, tostring(default_arg))
		end

		-- get rid of trailing commas
		if i ~= #generic_default_pairs - 1 then
			table.insert(file_contents, ", ")
		end
	end

	table.insert(file_contents, ">")
end

const function render_type_alias(file_contents: { string }, node: types.CstStatTypeAlias)
	const type_name: string = node.name.text

	-- pairs where (generic, default?)
	const generics: { string | false } = {}

	-- do nothing if its nil
	for _, generic_node in node.generics or {} do
		table.insert(generics, generic_node.name.text)

		if generic_node.default then
			table.insert(generics, " = " .. print_trimmed(generic_node.default))
		else
			table.insert(generics, false :: false)
		end
	end

	-- do nothing if its nil
	for _, generic_node in node.genericPacks or {} do
		table.insert(generics, generic_node.name.text .. "...")

		if generic_node.default then
			table.insert(generics, " = " .. print_trimmed(generic_node.default))
		else
			table.insert(generics, false :: false)
		end
	end

	table.insert(file_contents, `export type {type_name}`)
	render_generic_array(file_contents, generics, true)

	table.insert(file_contents, ` = REQUIRED_MODULE.{type_name}`)
	render_generic_array(file_contents, generics, false)

	table.insert(file_contents, "\n")
end

const function render_type_function(file_contents: { string }, node: types.CstStatTypeFunction)
	const type_fn_params: { string } = {}
	const type_fn_name = node.name.text

	for _, parameter in node.body.parameters do
		table.insert(type_fn_params, parameter.name.text)
	end

	table.insert(file_contents, `export type {type_fn_name}`)
	if #type_fn_params ~= 0 then
		table.insert(file_contents, "<")
		table.insert(file_contents, table.concat(type_fn_params, ", "))
		table.insert(file_contents, ">")
	end

	table.insert(file_contents, ` = REQUIRED_MODULE.{type_fn_name}`)
	table.insert(file_contents, "<")
	table.insert(file_contents, table.concat(type_fn_params, ", "))
	table.insert(file_contents, ">\n")
end

const function generate_linker_file(src: path.Path, dst: path.Path)
	const exported = query.findAllFromRoot(
		syntax.parse(fs.readFileToString(src)),
		function(node: types.CstNode): types.CstNode?
			if
				node.kind == "stat"
				and ((node.tag == "typealias" or node.tag == "typefunction") and node.isExported)
			then
				return node
			end

			return nil
		end
	)

	const source_path = path.dirname(path.resolve(dst))
	local entry_point = path.resolve(src)

	const entry_name = path.basename(entry_point)
	const is_init = entry_name == "init.luau" or entry_name == "init.lua"

	if is_init then
		entry_point = path.dirname(entry_point)
	end

	local relative = string.gsub(tostring(path.relative(source_path, entry_point)), "\\", "/")

	-- bruh
	-- TODO: fix this mess
	-- require paths never include the extension
	for _, extension in { ".luau", ".lua" } do
		if not is_init and string.sub(relative, -#extension) == extension then
			relative = string.sub(relative, 1, -#extension - 1)
			break
		end
	end

	-- luau only treats paths starting with ./ or ../ as relative, and a bare . or .. is not a path
	if relative == "." or relative == ".." then
		relative = `{relative}/`
	elseif string.sub(relative, 1, 2) ~= "./" and string.sub(relative, 1, 3) ~= "../" then
		relative = "./" .. relative
	end

	const file_contents: { string } = {
		`const REQUIRED_MODULE = require("{relative}")\n`,
	}

	for _, node: types.CstType in exported.nodes :: { types.CstNode } do
		if node.tag == "typealias" then
			render_type_alias(file_contents, node)
		elseif node.tag == "typefunction" then
			render_type_function(file_contents, node)
		end
	end

	table.insert(file_contents, "return REQUIRED_MODULE")

	fs.writeStringToFile(dst, table.concat(file_contents))
end

return generate_linker_file
