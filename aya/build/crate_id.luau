const pkg_id = require("@aya/pkg/utils/pkg_id")

export type CrateName = string

const crate_id = {}

function crate_id.get(pkg_identifier: pkg_id.Identifier, crate_name: CrateName): string
	return `{pkg_identifier}.crate-{crate_name}`
end

return table.freeze(crate_id)
