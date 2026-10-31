const config_ctx_ty = require("@self/config_ctx_ty")
const luau_config = require("@pkgs/luau_config")
const path = require("@std/path")

const conf_handle = luau_config.new(config_ctx_ty, {})

const config = {
	handle = conf_handle,
}

function config.read(location: path.Pathlike): config_ctx_ty.Identity end

return config
