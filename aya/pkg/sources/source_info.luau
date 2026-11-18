export type Git = {
	type: "git",
	remote: string,
}

export type Fake = {
	type: "fake",
}

export type Identity = Git | Fake

return nil
