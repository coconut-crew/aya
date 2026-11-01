# aya package design

## build.luau

equivalent of build.rs

## Workspace

- the thing u actually work in / edit code in, this is where build directory lives, cache lives, etc. its the git repo

## Package

- this may be like. server, shared, it has lots of build time config and its where u specify dependencies
- packages can be: static (shared, utils, etc.), interface (packages), artifacts (server, client, client_first).
- u can have multiple packages defined in one project.

## Target

- buildable object

## PlaceFile

- roblox place file output, it is built from multiple artifacts

# project hierarchy

```
src/
	|- server/          # each server, client, shared is a package.
		|-.aya.luau
	|- client/
		|-.aya.luau
	|- shared/
		|-.aya.luau
		|-util.luau
		|-random_subfolder/
```

# stuff

A tooling suite designed to make developing Roblox games fast, safe, secure, and modular.

## Aya Test

A testing framework with the intent of providing:

- Fuzz testing
- Unit testing
- Goldenfile testing
- Mutation testing
- Automated benchmark comparisons

## Aya Make

A meta-build tool for Luau. Intends to support:

- Modular source code transformation:
    - Dependencies providing transformers (e.g. your project providing a macro transformer)
    - Project-provided transformers (e.g. fluid providing luau-xml)
- Easy integration w/ your own systems, e.g. a content bundler.
- luau-defined project configuration
- A sourcemap (not the Roblox one, an actual source map)

## Aya Compose

A tool designed to integrate Aya projects into Roblox. Intends to support:

- Modular `.rbxl`s (a dependency can say, "put a remote named `JABBY_RELIABLE_REMOTE` in ReplicatedStorage")
- Rojo building and syncing

## Aya Iac (pending name)

- Deploys Roblox games
- Manages active Roblox games

## Aya Template

- Manages project templates

## Aya Pkg

- Git-based package manager using require-by-string and allowing for integration with the rest of aya.
