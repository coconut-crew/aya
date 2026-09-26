const subcommand_ty = require("@common/subcommand_ty")
const installation = require("@self/installation")
const manifest = require("@self/manifest")
const path = require("@std/path")
const process = require("@std/process")
const cli = require("@vendor/cli")

const function install()
	const project_manifest = manifest.read(path.join(process.cwd(), "ayapkg.toml"))

	installation.install_dependencies(project_manifest)
end

const pkg: subcommand_ty.Subcommand = {
	run = function(args)
		if args[1] == "install" then
			install()
		end
	end,
}

return pkg
