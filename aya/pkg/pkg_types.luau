const path = require("@std/path")
const type_fns = require("@vendor/type_fns")

export type GitInstall = {
	type: "git",

	remote: string,
	branch: string,
	revision: string,
	subpath: path.Pathlike?,
}

export type PathInstall = {
	type: "path",

	src_path: path.Pathlike,
}

export type Install = GitInstall | PathInstall

--[[ Actions ]]

type BaseInstallPackage = {
	kind: "install_package",
	location: path.Pathlike,
	alias: string,
}

type BaseRemovePackage = {
	kind: "remove_package",
	alias: string,
}

-- Path action providers
type AddPackage = {
	action: "add",
	install: Install,
}

type RemovePackage = {
	action: "remove",
	install: Install,
}

export type PackageManagementAction = AddPackage

return nil
