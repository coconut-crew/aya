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

-- Path action providers
type AddPackage = {
	action: "add",
	install: Install,
}

type RemovePackage = {
	action: "remove",
	install: Install,
}

export type PackageManagementAction = AddPackage | RemovePackage

return nil
