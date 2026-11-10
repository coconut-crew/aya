const path = require("@std/path")
const type_fns = require("@vendor/type_fns")

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
export type PathInstallPackage = type_fns.Extend<BaseInstallPackage, {
	provider: "path",
	location: path.Pathlike,
}>

export type PathRemovePackage = type_fns.Extend<BaseRemovePackage, {
	provider: "path",
}>

-- Git action providers
export type GitInstallPackage = type_fns.Extend<BaseInstallPackage, {
	provider: "git",
	remote: string,
	branch: string,
	revision: string,
}>

export type GitRemovePackage = type_fns.Extend<BaseRemovePackage, {
	provider: "git",
}>

export type PackageManagementAction = GitInstallPackage | GitRemovePackage

return nil
