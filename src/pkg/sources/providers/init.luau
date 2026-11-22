const colorful = require("@pkg/colorful")
const create_provider = require("@src/pkg/sources/create_provider")
const log = require("@src/common/log")
const path = require("@std/path")
const pkg_id = require("@src/pkg/utils/pkg_id")
const semver = require("@src/pkg/utils/semver")
const source_info = require("@src/pkg/sources/source_info")

type SourceInfo = source_info.Identity

const providers = {
	list = {} :: { [string]: create_provider.Identity<SourceInfo> },
	pkgs = {} :: source_info.Sources,
}

function providers.add_provider(
	provider_name: string,
	constructor: create_provider.Constructor<any>
)
	providers.list[provider_name] = constructor(providers.pkgs)
end

function providers.add_package(name: pkg_id.GlobalName, src: SourceInfo)
	providers.pkgs[name] = src
end

const function provider_of(name: pkg_id.GlobalName): create_provider.Identity<SourceInfo>
	const src = providers.pkgs[name]
	assert(src, `package {name} does not have a source`)

	const provider = providers.list[src.type]
	assert(provider, `no active provider named {src.type}`)

	return provider
end

function providers.download_async(
	name: pkg_id.GlobalName,
	version: semver.Identity,
	at: path.Pathlike
)
	provider_of(name).download_async(name, version, at)
	log.success(
		`downloaded package {colorful.styles.keyword(name .. "@" .. semver.print(version))}`
	)
end

function providers.get_dependencies_async(
	name: pkg_id.GlobalName,
	version: semver.Identity
): create_provider.DependencySet
	return provider_of(name).get_dependencies_async(name, version)
end

function providers.get_versions_async(name: pkg_id.GlobalName): { semver.Identity }
	return provider_of(name).get_versions_async(name)
end

return providers
