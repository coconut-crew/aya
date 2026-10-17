const pretty_print = require("@aya-common/utils/pretty_print")
const luau_config = require("@pkgs/luau_config")
const path = require("@std/path")

-- Style violation: We want types to be right next to the aya library definitions.
const aya_lib = luau_config.library<<BuildfileCtx>>("make")

type Dependency = {
	entry_point: { string },
}
aya_lib:add_type("Dependency", [[]])

type Executable = {
	entry_point: path.Pathlike,
	deps: { Dependency },
}
aya_lib:add_type(
	"ExecutableConfig",
	[[{
	entry_point: string,
	deps: { Dependency },
}]]
)

type BuildfileCtx = {
	executables: { Executable },
}

const function construct_buildfile_ctx(loc: path.Path): BuildfileCtx
	return {
		executables = {},
	}
end

aya_lib:add_function("executable", "(conf: ExecutableConfig) -> ()", function(ctx: BuildfileCtx, conf) end)

const buildfile_conf = luau_config.new<<BuildfileCtx>>(construct_buildfile_ctx, {})

aya_lib:write_interface("aya_defs.luau")

buildfile_conf:add_library(aya_lib)

pretty_print(buildfile_conf:run("./meow.luau"))
