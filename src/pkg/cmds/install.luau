const exit = require("@src/common/exit")
const git = require("@src/pkg/sources/providers/git")
const manifest = require("@src/manifest")
const path = require("@std/path")
const process = require("@std/process")
const providers = require("@src/pkg/sources/providers")
const resolver = require("@src/pkg/resolver")

const function install(workspace: path.Pathlike): never
	const config = manifest.find_closest_config(workspace)
	if not config then
		return exit("WORKSPACE_NO_MANIFEST")
	end

	const a = manifest.read_from(config)

	const resolver_ranges: resolver.Ranges = {}

	providers.add_provider("git", git)

	for name, data in a.dependencies do
		resolver_ranges[data.global_name] = data.version
		providers.add_package(name, data.source)
	end

	const solved = resolver.solve(resolver_ranges)

	for key, value in solved do
		providers.download_async(key, value, "tmptest")
	end

	process.exit(0)
end

install(process.cwd())

return install
