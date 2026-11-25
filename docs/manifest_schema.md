# Workspace

```toml
# "workspace.aya.toml" at project root
#	Workspace-level configs. The build directory is placed alongside the file w/ workspace configuration.
[workspace]

# Array of paths mapping to package configuration files
members = [""]

lints = [
	"lints"
]

# Development dependencies required to work on this project.
# Standard dependency declarations
[workspace.dev_dependencies]
lints = { version = "0.1.0", github = "coconut-crew" }
```

# Package

```toml
# "packages/server/package.aya.toml"
#	Package-level configuration, completely independent of workspace-level config
[package]

# Optional
name = "server"

# Semver is forced here
version = "0.1.0"

# Standard dependency declaration
[dependencies]
log = { version = "0.1.0", github = "coconut-crew" }

[crates]

[crates.root]
path = ""
visibility = "private"
```

## Invariants

- Git repos must have `workspace` and `package` be defined in the same place
