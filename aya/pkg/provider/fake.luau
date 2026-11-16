const pkg_id = require("@aya/pkg/pkg_id")
const semver = require("@aya/pkg/utils/semver")
const semver_range = require("@aya/pkg/utils/semver_range")

export type Registry = {
	-- global name: { [version]: { dependency list } }
	[pkg_id.GlobalName]: { [string]: { [pkg_id.GlobalName]: semver_range.Identity } },
}

const fake = {
	registry = {} :: Registry,
}

function fake.download_async(global_name: pkg_id.GlobalName, version: semver.Identity) end

function fake.dependencies_of_async(global_name: pkg_id.GlobalName, version: semver.Identity)
	return fake.registry[global_name][semver.print(version)]
end

function fake.get_versions_async(global_name: pkg_id.GlobalName): { semver.Identity }
	const result = {}

	const version_list = fake.registry[global_name]
	for version_string in version_list do
		table.insert(result, semver.parse(version_string))
	end

	return result
end

return fake
