const luau_conf = require("@common/luau_conf")
const luau = require("@std/luau")
const path = require("@std/path")

export type BuildfileContext = {
	working_dir: path.Path,

	project_decls: {},
	object_decls: {},
}

const function ctx_constructor(buildfile_path: path.Path)
	const ctx: BuildfileContext = {
		working_dir = buildfile_path,

		project_decls = {},
		object_decls = {},
	}

	return ctx
end

const luauconf_runner = luau_conf.new<<BuildfileContext>>(ctx_constructor)

luauconf_runner:add_function("require", function(ctx: BuildfileContext, module_path)
	assert(type(module_path) == "string", `Module path must be a string`)

	const resolved = path.parse(luau.resolveModule(module_path, ctx.working_dir))

	luauconf_runner:file(resolved)
end)

const buildfile = {}

function buildfile.run(buildfile_path: path.Path) end

return table.freeze(buildfile)
