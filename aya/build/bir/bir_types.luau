const path = require("@std/path")

export type BirRuleset = {}

export type BirCompileFile = {
	src: path.Pathlike,
	dst: path.Pathlike,

	rules: BirRuleset,
}
