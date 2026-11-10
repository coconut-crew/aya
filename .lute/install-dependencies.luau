const installation = require("@aya/cmds/pkg/installation")
const manifest = require("@aya/cmds/pkg/manifest")
const path = require("@std/path")
const process = require("@std/process")

const function install(set_path: string?)
	-- const project_manifest = manifest.read(path.join(process.cwd(), "ayapkg.toml"))
	const new_path = if set_path then path.join(process.cwd(), set_path) else process.cwd()

	installation.install_dependencies(path.join(new_path, "ayapkg.toml"), { root = tostring(new_path), installed = {} })
end

install()
