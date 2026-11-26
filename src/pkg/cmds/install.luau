const app_dirs = require("@src/common/app_dirs")
const exit = require("@src/common/exit")
const git = require("@src/pkg/sources/providers/git")
const hash_directory = require("@src/common/utils/hash_directory")
const lockfile = require("@src/pkg/lockfile")
const manifest = require("@src/manifest")
const path = require("@std/path")
const pkg_id = require("@src/pkg/utils/pkg_id")
const process = require("@std/process")
const providers = require("@src/pkg/sources/providers")
const resolver = require("@src/pkg/resolver")
const semver = require("@src/pkg/utils/semver")

const function install(workspace: path.Pathlike): never
	const config = manifest.find_closest_config(workspace)
	if not config then
		return exit("WORKSPACE_NO_MANIFEST")
	end

	const project_dir = path.dirname(config)
	const project_manifest = manifest.read_from(config)
	const previously_locked = lockfile.read(project_dir) or {}

	providers.add_provider("git", git)

	const resolver_ranges: resolver.Ranges = {}
	for name, data in project_manifest.dependencies do
		resolver_ranges[data.global_name] = data.version
		providers.add_package(name, data.source)
	end

	const solved = resolver.solve(resolver_ranges, lockfile.identifiers(previously_locked))

	const packages_dir = path.join(app_dirs.ensure("cache"), "packages")
	const locked: lockfile.Identity = {}
	for name, version in solved do
		const identifier = pkg_id.identifier(name, version)
		const at = path.join(packages_dir, identifier)
		providers.download_async(name, version, at)

		const checksum = hash_directory(at)
		const previous = previously_locked[name]
		if
			previous
			and semver.equals(previous.version, version)
			and previous.checksum ~= checksum
		then
			return exit("LOCKFILE_CHECKSUM_MISMATCH", identifier, previous.checksum, checksum)
		end

		locked[name] = { version = version, checksum = checksum }
	end

	lockfile.write_async(locked, project_dir)

	return process.exit(0)
end

return install
