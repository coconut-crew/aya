const pkg_id = require("@aya/pkg/utils/pkg_id")

export type Git = {
	type: "git",
	remote: string,
}

export type Fake = {
	type: "fake",
}

export type Identity = Git | Fake

-- { [package name]: where that package comes from }
export type Sources = { [pkg_id.GlobalName]: Identity }

return nil
