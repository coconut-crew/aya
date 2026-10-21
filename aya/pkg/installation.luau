const fs = require("@std/fs")
const path = require("@std/path")
const process = require("@std/process")
const glob = require("@common/glob")
const text_styling = require("@common/text_styling")
const env = require("@std/test/env")
const generate_linker_file = require("./generate_linker_file")
const manifest = require("./manifest")

const installation = {}

function installation.clone(project_manifest: manifest.Identity, dependency: string, output: string)
	assert(project_manifest.monorepo == false)
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

function installation.install_dependencies(ayapkg: path.Path, environment: Environment)
	const package_folder = path.dirname(ayapkg)
	const ayamanifest = manifest.read(ayapkg)

	if ayamanifest.monorepo then
		const matching_packages_list = glob.discover(path.join(package_folder, ayamanifest.packages))

		for _, pkg in matching_packages_list do
			const ayapkg_manifest = path.join(pkg, "ayapkg.toml")

			if fs.exists(ayapkg_manifest) == false then
				print(text_styling.warn(`{pkg} matched the glob in {package_folder}, but no ayapkg.toml can be found`))
				continue
			end

			installation.install_dependencies(ayapkg_manifest, environment)
		end
	elseif ayamanifest.monorepo == false then
		for dep_name, dependency in ayamanifest.dependency do
			local require_path

			-- relative dependency
			if dependency.remote == nil and dependency.branch == nil and dependency.commit == nil then
				const ayapkg_manifest_location = path.join(package_folder, dependency.from_path, "ayapkg.toml")

				if fs.exists(ayapkg_manifest_location) == false then
					print(text_styling.warn(`ayapkg.toml is missing from {path.join(package_folder, dependency.from_path)} which is a dependency of {package_folder}`))
					continue
				end

				const dependency_manifest = manifest.read(ayapkg_manifest_location)

				if dependency_manifest.monorepo then
					print(text_styling.failure(`cannot depend on {path.join(package_folder, dependency.from_path)}, as it is a monorepo. from {package_folder}`))
					continue
				end

				if dependency_manifest.entry_point == false then
					print(text_styling.failure(`cannot depend on {path.join(package_folder, dependency.from_path)}, as there's no entry point. from {package_folder}`))
					continue
				end

				require_path = path.join(package_folder, dependency.from_path, dependency_manifest.entry_point)
			-- git dependency
			elseif dependency.remote and dependency.branch and dependency.commit then
				-- check if the package exists
				const id = `git#{dependency.remote}+{dependency.branch}+{dependency.commit}`
				const git_path = path.resolve(environment.root, "pkgs", "_index", id)

				if fs.exists(path.join(environment.root, "pkgs", "_index", id)) == false then
					installation.clone(ayamanifest, dep_name, tostring(git_path))
				else
					installation.fetch(ayamanifest, dep_name, tostring(git_path))
				end

				const package_path = if dependency.from_path then path.join(git_path, dependency.from_path) else git_path
				const manifest_path = path.join(package_path, "ayapkg.toml")

				if fs.exists(manifest_path) == false then
					print(text_styling.failure(`ayapkg.toml is missing from {package_path} which is a dependency of {package_folder}`))
					continue
				end

				const manifest_file = manifest.read(manifest_path)

				if manifest_file.monorepo then
					print(text_styling.failure(`cannot depend on {package_path}, as it is a monorepo. from {package_folder}`))
					continue
				end

				if dependency_manifest.entry_point == false then
					print(text_styling.failure(`cannot depend on {package_path}, as there's no entry point. from {package_folder}`))
					continue
				end

				-- link the package
				if fs.exists(path.join(environment.root, "pkgs", "_index", id)) then
					generate_linker_file(package_entry_point, path.join(package_folder, "links", id), require_path)
				end
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
