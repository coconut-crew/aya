const fake = require("@aya/pkg/provider/fake")
const path = require("@std/path")
const pkg_id = require("@aya/pkg/pkg_id")
const semver = require("@aya/pkg/utils/semver")
const semver_range = require("@aya/pkg/utils/semver_range")

export type GitSourceInfo = {
	type: "git",
	remote: string,
}

export type LocalPathSourceInfo = {
	type: "local_path",
	src: path.Pathlike,
}

-- used for testing
export type FakeSourceInfo = {
	type: "fake",
	name: string,
}

export type SourceInfo = LocalPathSourceInfo | GitSourceInfo | FakeSourceInfo

const provider = {
	pkg_source_map = {} :: { [pkg_id.GlobalName]: SourceInfo },
}

function provider.source_for(global_name: pkg_id.GlobalName): SourceInfo
	return provider.pkg_source_map[global_name]
end

function provider.download_async(name: pkg_id.GlobalName, version: semver.Identity) end

function provider.get_versions_async(global_name: pkg_id.GlobalName): { semver.Identity }
	const source_info = provider.pkg_source_map[global_name]
	assert(source_info ~= nil, "")

	if source_info.type == "fake" then
		return fake.get_versions_async(global_name)
	end
end

function provider.dependencies_of_async(
	global_name: pkg_id.GlobalName,
	version: semver.Identity
): { [string]: semver_range.Identity }
	const source_info = provider.pkg_source_map[global_name]
	assert(source_info ~= nil, "")

	if source_info.type == "fake" then
		return fake.dependencies_of_async(global_name, version)
	end
end

function provider.set_source(global_name: pkg_id.GlobalName, src_info: SourceInfo)
	provider.pkg_source_map[global_name] = src_info
end

return provider
