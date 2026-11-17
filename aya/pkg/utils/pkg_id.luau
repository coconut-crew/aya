const semver = require("@aya/pkg/utils/semver")

-- Since names are globally namespaced, a package's name is unique to that package.
-- Package names are also case insensitive.
export type GlobalName = string

-- GlobalName + Version
export type Identifier = string

const pkg_id = {}

-- we might want to do something interesting with this later
-- for now its just making things case insensitive
function pkg_id.global_name(name: string): GlobalName
	return string.lower(name)
end

function pkg_id.identifier(name: string, version: semver.Identity): Identifier
	return `{pkg_id.global_name(name)}@{semver.print(version)}`
end

return table.freeze(pkg_id)
