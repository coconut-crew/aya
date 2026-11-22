const pkg_id = require("@src/pkg/utils/pkg_id")

export type Git = {
	type: "git",
	remote: string,

	rev: string?,
}

export type Fake = {
	type: "fake",
}

export type Identity = Git | Fake

export type Sources = { [pkg_id.GlobalName]: Identity }

return nil
