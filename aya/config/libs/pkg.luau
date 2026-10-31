const luau_config = require("@pkgs/luau_config")

const lib = luau_config.library("pkg")

type Dependency = {}
lib:add_type(
	"Dependency",
	[[{
}]]
)

lib:add_function("", type_signature, fn)
