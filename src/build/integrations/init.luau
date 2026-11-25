const fs = require("@std/fs")
const luau = require("@lute/luau")
const path = require("@std/path")
const printer = require("@std/syntax/printer")
const syntax = require("@std/syntax")

type TransformerCtx = {
	src_path: path.Pathlike,
	plaintext: string,
	parsed: syntax.CstParseResult,

	opts: {
		[string]: string?,
	},
}

const integrations = {}

function integrations.apply_transformers(
	src: path.Pathlike,
	dst: path.Pathlike,
	transformers: { path.Pathlike }
)
	-- Load
	const transform_fns = {}

	for _, transformer_path in transformers do
		const bytecode = luau.compile(fs.readFileToString(transformer_path), {
			optimizationlevel = 2,
		})
		const loaded = luau.load(bytecode, `={path.format(transformer_path)}`)

		transform_fns[path.format(transformer_path)] = loaded()
	end

	-- Run
	const src_content = fs.readFileToString(src)
	const parse_result = syntax.parse(src_content)

	const ctx: TransformerCtx = {
		src_path = src,
		plaintext = fs.readFileToString(src_content),
		parsed = parse_result,
		opts = {},
	}

	-- visitor stuff

	-- Write

	fs.writeStringToFile(dst, printer.printFile(ctx.parsed))

	return ctx
end

return table.freeze(integrations)
