const path = require("@std/path")
const type_fns = require("@vendor/type_fns")

export type BaseObject = {
	uuid: string,
	location: path.Pathlike,
}

export type BuildObject = type_fns.CombineTableAndSetIndexer<BaseObject, {}>

export type TestObject = type_fns.CombineTableAndSetIndexer<BaseObject, {

	type: "test",
}>

export type TaskObject = type_fns.CombineTableAndSetIndexer<BaseObject, {
	alias: string,

	type: "task",
}>

export type IntegrationObject = type_fns.CombineTableAndSetIndexer<BaseObject, {
	type: "integration",
}>

export type TransformerObject = type_fns.CombineTableAndSetIndexer<BaseObject, {
	type: "transformer",
}>

-- stylua: ignore
export type Object =
	| TaskObject
	| TransformerObject
	| TestObject
	| IntegrationObject
	| BuildObject

export type DependencyDeclaration =
	{
		type: "path",
		location: path.Pathlike,
	}
	| {
		identifier: string,
		version: string,
	}

export type Workspace = {
	package_resolvers: { path.Pathlike },
}

export type Profile = {}

export type Target = {}

export type Crate = {
	exports: {
		modules: { path.Pathlike },
		tasks: { path.Pathlike },
		build_scripts: { path.Pathlike },
		transformers: { path.Pathlike },
	},

	dependencies: { DependencyDeclaration },
	dev_dependencies: { DependencyDeclaration },
}

local crate = {}
