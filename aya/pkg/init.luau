const subcommand_ty = require("@common/subcommand_ty")
const installation = require("@self/installation")
const manifest = require("@self/manifest")
const path = require("@std/path")
const process = require("@std/process")
const cli = require("@vendor/cli")

const function install(set_path: string?)
	-- const project_manifest = manifest.read(path.join(process.cwd(), "ayapkg.toml"))
	const new_path = if set_path then path.join(process.cwd(), set_path) else process.cwd()

	installation.install_dependencies(path.join(new_path, "ayapkg.toml"), { root = tostring(new_path), installed = {} })
end

const pkg: subcommand_ty.Subcommand = {
	run = function(args)
		if args[1] == "install" then
			install(args[2])
		end
	end,
}

return pkg
