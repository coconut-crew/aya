const pkg_id = require("@src/pkg/utils/pkg_id")

export type CrateName = string
export type Id = string

const crate = {}

function crate.id(pkg_identifier: pkg_id.Identifier, crate_name: CrateName): string
	return `{pkg_identifier}.crate-{crate_name}`
end

return table.freeze(crate)
