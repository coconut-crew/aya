const fs = require("@std/fs")
const path = require("@std/path")
const syntax = require("@std/syntax")
const query = require("@std/syntax/query")
const types = require("@std/syntax/types")

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
			table.insert(generics, " = " .. generic_node.default.name.text)
		else
			table.insert(generics, false :: false)
		end
	end

	-- do nothing if its nil
	for _, generic_node in node.genericPacks or {} do
		table.insert(generics, generic_node.name.text .. "...")

		if generic_node.default then
			table.insert(generics, " = ..." .. generic_node.default.type.name.text)
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

const function generate_linker_file(package_entry_point: path.Path, link_file_path: path.Path, require_path: string)
	const exported = query.findAllFromRoot(
		syntax.parse(fs.readFileToString(package_entry_point)),
		function(node: types.CstNode): types.CstNode?
			if node.kind == "stat" and ((node.tag == "typealias" or node.tag == "typefunction") and node.isExported) then
				return node
			end

			return nil
		end
	)

	const file_contents: { string } = {
		`const REQUIRED_MODULE = require("{require_path}")\n`,
	}

	for _, node: types.CstType in exported.nodes :: { types.CstNode } do
		if node.tag == "typealias" then
			render_type_alias(file_contents, node)
		elseif node.tag == "typefunction" then
			render_type_function(file_contents, node)
		end
	end

	table.insert(file_contents, "return REQUIRED_MODULE")

	fs.writeStringToFile(link_file_path, table.concat(file_contents))
end

return generate_linker_file
