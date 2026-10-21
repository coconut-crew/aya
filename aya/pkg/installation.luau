const env = require("@std/test/env")
const fs = require("@std/fs")
const generate_linker_file = require("./generate_linker_file")
const glob = require("@common/glob")
const manifest = require("./manifest")
const path = require("@std/path")
const process = require("@std/process")
const text_styling = require("@common/text_styling")

const installation = {}

function installation.clone(project_manifest: manifest.Identity, dependency: string, output: string)
	assert(project_manifest.monorepo ~= true)
	const config = project_manifest.dependency[dependency]
	assert(config.branch)
	assert(config.remote)
	assert(config.commit)

	process.run({
		"git",
		"clone",
		"--depth=1",
		`--revision={config.commit}`,
		config.remote,
		output,
	}, {
		stdio = "inherit",
	})
end

function installation.fetch(project_manifest: manifest.Identity, dependency: string, cwd: string)
	const pkg_config = project_manifest.dependency[dependency]

	process.run({
		`git`,
		"fetch",
		"--depth=1",
		"origin",
		pkg_config.commit,
	}, {
		stdio = "inherit",
		cwd = cwd,
	})

	process.run({
		`git`,
		"checkout",
		pkg_config.commit,
	}, {
		stdio = "inherit",
		cwd = cwd,
	})
end

export type Environment = {
	-- the root path where we will store all packages
	read root: path.Path,
	-- a list of dependencies which are already installed
	read installed: { [path.Path]: true },
}

const function get_manifest_file(origin_path: path.Pathlike, from_path: path.Pathlike?, dependency_of: path.Pathlike): manifest.Identity | false
	const package_path = if from_path then path.join(origin_path, from_path) else origin_path
	const ayapkg_manifest_location = path.join(package_path, "ayapkg.toml")

	if fs.exists(ayapkg_manifest_location) == false then
		print(text_styling.warn(`ayapkg.toml is missing from {package_path} which is a dependency of {dependency_of}`))
		return false
	end

	const dependency_manifest = manifest.read(ayapkg_manifest_location)

	return dependency_manifest
end

const function get_require_path(origin_path: path.Pathlike, from_path: path.Pathlike?, dependency_of: path.Pathlike): path.Pathlike | false?
	const package_path = if from_path then path.join(origin_path, from_path) else origin_path
	const dependency_manifest = get_manifest_file(origin_path, from_path, dependency_of)

	if dependency_manifest == false then
		return false
	end

	if dependency_manifest.monorepo then
		print(text_styling.failure(`cannot depend on {package_path}, as it is a monorepo. from {dependency_of}`))
		return false
	end

	if dependency_manifest.entry_point == false then
		print(text_styling.failure(`cannot depend on {package_path}, as there's no entry point. from {dependency_of}`))
		return false
	end

	return path.join(package_path, dependency_manifest.entry_point)
end

function installation.install_dependencies(ayapkg: path.Path, environment: Environment)
	const package_folder = path.dirname(ayapkg)
	const ayamanifest = manifest.read(ayapkg)

	if fs.exists(path.join(package_folder, "pkgs")) == false then
		fs.createDirectory(path.join(package_folder, "pkgs"))
	end
	if fs.exists(path.join(package_folder, "pkgs", "links")) == false then
		fs.createDirectory(path.join(package_folder, "pkgs", "links"), { makeParents = true })
	else
		fs.removeDirectory(path.join(package_folder, "pkgs", "links"), { recursive = true })
		fs.createDirectory(path.join(package_folder, "pkgs", "links"), { makeParents = true })
	end

	if ayamanifest.monorepo == true then
		const matching_packages_list = glob.discover(path.join(package_folder, ayamanifest.packages))

		for _, pkg in matching_packages_list do
			const ayapkg_manifest = path.join(pkg, "ayapkg.toml")

			if fs.exists(ayapkg_manifest) == false then
				print(text_styling.warn(`{pkg} matched the glob in {package_folder}, but no ayapkg.toml can be found`))
				continue
			end

			installation.install_dependencies(ayapkg_manifest, environment)
		end
	elseif ayamanifest.monorepo ~= true then
		for dep_name, dependency in ayamanifest.dependency do
			local require_path

			-- relative dependency
			if dependency.remote == nil and dependency.branch == nil and dependency.commit == nil then
				const package_path = path.join(package_folder, dependency.from_path)
				const ayapkg_manifest_location = path.join(package_path, "ayapkg.toml")

				installation.install_dependencies(ayapkg_manifest_location, environment)
				require_path = get_require_path(package_folder, dependency.from_path, package_folder)
			-- git dependency
			elseif dependency.remote and dependency.branch and dependency.commit then
				-- check if the package exists
				const id = `git#{dependency.commit}`
				const git_path = path.resolve(environment.root, "pkgs", "_index", id)
				print(environment.root)

				if fs.exists(git_path) == false then
					installation.clone(ayamanifest, dep_name, tostring(git_path))
				else
					installation.fetch(ayamanifest, dep_name, tostring(git_path))
				end

				const package_path = if dependency.from_path then path.join(git_path, dependency.from_path) else git_path
				const ayapkg_manifest_location = path.join(package_path, "ayapkg.toml")

				installation.install_dependencies(ayapkg_manifest_location, environment)
				require_path = get_require_path(git_path, dependency.from_path, package_folder)
			end

			-- link the package
			if require_path then
				generate_linker_file(path.normalize(require_path), path.join(package_folder, "pkgs", "links", `{dep_name}.luau`))
			else
				print(text_styling.warn(`missing require path for {dep_name} from {package_folder}`))
			end
		end
	end

	-- if not from_dependency then
	-- 	if not fs.exists("./pkgs") then
	-- 		fs.createDirectory("./pkgs")
	-- 	end

	-- 	if not fs.exists("./pkgs/_index/") then
	-- 		fs.createDirectory("./pkgs/_index")
	-- 	end

	-- 	if not fs.exists("./pkgs/links") then
	-- 		fs.createDirectory("./pkgs/links")
	-- 	end
	-- end

	-- for dependency_name, dependency in project_manifest.dependency do
	-- 	if dependency.from_path then
	-- 		const dep_exists = fs.exists(`./pkgs/_index/{dependency_name}`)
	-- 		if dep_exists then
	-- 			fs.removeDirectory(`./pkgs/_index/{dependency_name}`)
	-- 		end
	-- 	else
	-- 		const dep_exists = fs.exists(`./pkgs/_index/{dependency_name}`)
	-- 		if dep_exists then
	-- 			installation.fetch(project_manifest, dependency_name)
	-- 		elseif not dep_exists then
	-- 			installation.clone(project_manifest, dependency_name)
	-- 		end

	-- 		if not fs.exists(`./pkgs/_index/{dependency_name}/pkgs/`) then
	-- 			fs.createDirectory(`./pkgs/_index/{dependency_name}/pkgs/`)
	-- 		end

	-- 		if not fs.exists(`./pkgs/_index/{dependency_name}/pkgs/links`) then
	-- 			fs.createDirectory(`./pkgs/_index/{dependency_name}/pkgs/links`)
	-- 		end

	-- 		const dependency_manifest = manifest.get_pkg_manifest(dependency_name)

	-- 		installation.install_dependencies(dependency_manifest, dependency_name)

	-- 		if not dependency_manifest.entry_point then
	-- 			print("no entry point")
	-- 			continue
	-- 		end

	-- 		const dependency_entry_point = path.join(`pkgs/_index/{dependency_name}`, dependency_manifest.entry_point)

	-- 		const require_path = string.gsub(dependency_manifest.entry_point, "/init.luau", "")

	-- 		if not from_dependency then
	-- 			generate_linker_file(
	-- 				dependency_entry_point,
	-- 				path.parse(`pkgs/links/{dependency_name}.luau`),
	-- 				`../_index/{dependency_name}/{require_path}`
	-- 			)
	-- 		else
	-- 			generate_linker_file(
	-- 				dependency_entry_point,
	-- 				path.join(`./pkgs/_index/{from_dependency}`, `pkgs/links/{dependency_name}.luau`),
	-- 				`../../../{dependency_name}/{require_path}`
	-- 			)
	-- 		end
	-- 	end
	-- end
end

return installation
