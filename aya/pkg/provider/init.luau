const fake = require("@aya/pkg/provider/fake")
const git = require("@aya/pkg/provider/git")
const path = require("@std/path")
const pkg_id = require("@aya/pkg/utils/pkg_id")
const provider_tys = require("@aya/pkg/provider/provider_tys")
const semver = require("@aya/pkg/utils/semver")
const semver_range = require("@aya/pkg/utils/semver_range")

const prov_list: { [("git" | "fake")]: provider_tys.SourceProvider<any> } = {}

const provider = {
	initialized = false,

	pkg_source_map = {} :: { [pkg_id.GlobalName]: provider_tys.SourceInfo },
}

function provider.init(to_include: { [("git" | "fake")]: true? }?)
	if to_include then
	end
	prov_list.fake = fake.provider()
	prov_list.git = git.provider()

	provider.initialized = true
end

function provider.download_async(
	global_name: pkg_id.GlobalName,
	version: semver.Identity,
	at: path.Pathlike
)
	assert(provider.initialized, `provider is not initialized yet`)

	const source_info = provider.pkg_source_map[global_name]
	assert(source_info ~= nil, "")

	return prov_list[source_info.type].download_async(global_name, version, at)
end

function provider.get_versions_async(global_name: pkg_id.GlobalName): { semver.Identity }
	assert(provider.initialized, `provider is not initialized yet`)

	const source_info = provider.pkg_source_map[global_name]
	assert(source_info ~= nil, "")

	return prov_list[source_info.type].get_versions_async(global_name)
end

function provider.get_dependencies_async(
	global_name: pkg_id.GlobalName,
	version: semver.Identity
): { [string]: semver_range.Identity }
	assert(provider.initialized, `provider is not initialized yet`)

	const source_info = provider.pkg_source_map[global_name]
	assert(source_info ~= nil, "")

	return prov_list[source_info.type].get_dependencies_async(global_name, version)
end

function provider.set_source(global_name: pkg_id.GlobalName, src_info: provider_tys.SourceInfo)
	provider.pkg_source_map[global_name] = src_info
end

return provider
