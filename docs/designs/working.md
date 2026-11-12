# Design

## Workspaces

A "workspace" is effectively the editor environment. It is where the `build` folder lives, it is where root-level configuration resides, and it is where lints and build tooling is defined.

### Workspace Dependencies

Workspace dependencies are dependencies needed to build or upload the project. e.g. `aya-compose`, `iac`, etc. are workspace dependencies. A package's workspace dependencies are inherited: if `viewmodel` needs workspace dependency `content_store`, `content_store` will be available in the _entire workspace_.

## Crates

Crates are units of code. They can "export" any number of files. Exporting a file makes it accessible to other crates. Crates are what the build system produces.

### Running crates

A crate should have many different ways of being ran. A Roblox game may be built by requiring `client` and `server` crates to be specified, which must export a `main` file which has an `export function main()` statement. A CLI tool may require something similar.

Counter-intuitively, a crate should not specify how it is ran, as that is of no interest to the crate. The package describes the system at a high-level, and as such, the package should be the one to specify, say, `cs_cli` is a command-line interface.

### Linking crates / Crate dependencies

Crates are unable to require eachother unless explicitly declared. To accomplish this, a `./build/crate_links/` directory is created filled with each crate's linker files. `.config.luau` files are generated alongside the crate configuration for analysis & tooling.

## Packages

Packages bundle crates. A `content_management` package may come with crates like `cm_registry` or `cm_reflection`.

### "Primary" crate

For convenience, a package may choose to export only _one_ crate. This is useful for utility packages, or packages which do not care about execution context.

### Example

```toml
[package]
name = "content_management"
version = "0.1.0"
edition = "0.1.0"

[dependencies]
log = { version = "whatever" }

[crate.server]
dir = "crates/cm/server"
needs = [
	"log/server",

	# Not specifying a package == defaults to this crate
	# so this is equivalent to "content_management/shared"
	"shared"
]
exports = [
	# Relative to the crate
	"registry.luau"
]

[crate.cli]
dir = "crates/cm/cli"
needs = [
	# Main exports don't need to "index" the pacakge
	"log"
]
exports = []

[crate.shared]
dir = "crates/cm/shared"
needs = [
	"log",
]
exports = [
	# Supports glob exports if you just wanna export everything
	"/**"
]

# Shell commands aren't limited to crates
[bin.cli]
aliases = ["cm", "content-management", "cm-reflection"]
entry = "cli/main.luau"
```

# Components

- **Config:** Config files drive most of these concepts, and as such are a "common language". If this design doesn't work out, it will break here.
- **Build System (`aya make`):** This is effectively Babel for Luau, and it's also what powers all of these subcommands. This is really 5 different things dressed in one.
    - **Package Linking / Bundling:** This is the primary feature.
    - **Transformers:** Plugins are not within scope for the first iteration.
- **Package Management (`aya pkg`):** Unnecessary to do anything significantly complex here.

### Secondary Components (supported by tasks)

- Infrastructure as Code (`aya iac`)
- Compose (`aya compose`)
