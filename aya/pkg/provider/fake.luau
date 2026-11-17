const path = require("@std/path")
const pkg_id = require("@aya/pkg/pkg_id")
const provider_tys = require("@aya/pkg/provider/provider_tys")
const semver = require("@aya/pkg/utils/semver")

const fake = {
	registry = {} :: provider_tys.Registry,
}

function fake.provider(): provider_tys.SourceProvider<nil>
	const provider: provider_tys.SourceProvider<nil> = {} :: never

	function provider.download_async(
		global_name: pkg_id.GlobalName,
		version: semver.Identity,
		at: path.Pathlike
	)
	end

	function provider.get_dependencies_async(
		global_name: pkg_id.GlobalName,
		version: semver.Identity
	)
		return fake.registry[global_name][semver.print(version)]
	end

	function provider.get_versions_async(global_name: pkg_id.GlobalName): { semver.Identity }
		const result = {}

		const version_list = fake.registry[global_name]
		for version_string in version_list do
			table.insert(result, semver.parse(version_string))
		end

		table.sort(result, semver.newer)

		return result
	end

	function provider.set_info(global_name: pkg_id.GlobalName, info: nil)
		-- blank stub fn
	end

	return provider
end

return fake
