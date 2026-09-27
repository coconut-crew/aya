const fs = require("@std/fs")
const path = require("@std/path")
const process = require("@std/process")
const generate_linker_file = require("./generate_linker_file")
const manifest = require("./manifest")

const installation = {}

function installation.clone(project_manifest: manifest.Identity, dependency: string)
	const config = project_manifest.dependency[dependency]

	process.run({
		"git",
		"clone",
		"--depth=1",
		`--revision={config.commit}`,
		config.remote,
		`pkgs/_index/{dependency}`,
	}, {
		stdio = "inherit",
	})
end

function installation.fetch(project_manifest: manifest.Identity, dependency: string)
	const pkg_config = project_manifest.dependency[dependency]
	const repo_cwd = `pkgs/_index/{dependency}`

	process.run({
		`git`,
		"fetch",
		"--depth=1",
		"origin",
		pkg_config.commit,
	}, {
		stdio = "inherit",
		cwd = repo_cwd,
	})

	process.run({
		`git`,
		"checkout",
		pkg_config.commit,
	}, {
		stdio = "inherit",
		cwd = repo_cwd,
	})
end

function installation.install_dependencies(project_manifest: manifest.Identity, from_dependency: string?)
	if not from_dependency then
		if not fs.exists("./pkgs") then
			fs.createDirectory("./pkgs")
		end

		if not fs.exists("./pkgs/_index/") then
			fs.createDirectory("./pkgs/_index")
		end

		if not fs.exists("./pkgs/links") then
			fs.createDirectory("./pkgs/links")
		end
	end

	for dependency_name in project_manifest.dependency do
		const dep_exists = fs.exists(`./pkgs/_index/{dependency_name}`)
		if dep_exists then
			installation.fetch(project_manifest, dependency_name)
		elseif not dep_exists then
			installation.clone(project_manifest, dependency_name)
		end

		if not fs.exists(`./pkgs/_index/{dependency_name}/pkgs/`) then
			fs.createDirectory(`./pkgs/_index/{dependency_name}/pkgs/`)
		end

		if not fs.exists(`./pkgs/_index/{dependency_name}/pkgs/links`) then
			fs.createDirectory(`./pkgs/_index/{dependency_name}/pkgs/links`)
		end

		const dependency_manifest = manifest.get_pkg_manifest(dependency_name)

		installation.install_dependencies(dependency_manifest, dependency_name)

		if not dependency_manifest.entry_point then
			print("no entry point")
			continue
		end

		const dependency_entry_point = path.join(`pkgs/_index/{dependency_name}`, dependency_manifest.entry_point)

		const require_path = string.gsub(dependency_manifest.entry_point, "/init.luau", "")

		if not from_dependency then
			generate_linker_file(
				dependency_entry_point,
				path.parse(`pkgs/links/{dependency_name}.luau`),
				`../_index/{dependency_name}/{require_path}`
			)
		else
			generate_linker_file(
				dependency_entry_point,
				path.join(`./pkgs/_index/{from_dependency}`, `pkgs/links/{dependency_name}.luau`),
				`../../../{dependency_name}/{require_path}`
			)
		end
	end
end

return installation
