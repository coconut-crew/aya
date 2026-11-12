export type Identity = {
	name: string,

	crates: {},
}

const package = {}

function package.init() end

return table.freeze(package)
