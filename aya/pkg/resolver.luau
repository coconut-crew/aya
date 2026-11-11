const pkg_id = require("@aya/pkg/pkg_id")
const pkg_types = require("@aya/pkg/pkg_types")

type DepGraphRoot = {
	dependencies: { DepGraphNode },
}

type DepGraphGitNode = {
	type: "git",
	install: pkg_types.GitInstall,
	dependencies: { DepGraphNode },
}

type DepGraphPathNode = {
	type: "path",
	install: pkg_types.PathInstall,
	dependencies: { DepGraphNode },
}

type UNUSED_DepGraphRegistryNode = {
	type: "registry",
	install: nil,
	version: string,
	dependencies: { DepGraphNode },
}

type DepGraphNode = DepGraphGitNode | DepGraphPathNode

-- [dependency package version]
type DependencyResult = {
	[pkg_id.Identity]: {
		install: nil,
	},
}

const resolver = {}

function resolver.parse(root: DepGraphRoot)
	for _, dep in root.dependencies do
	end
end

return table.freeze(resolver)
