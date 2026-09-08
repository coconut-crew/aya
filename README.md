# aya

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
-

## Aya Compose

A tool designed to integrate Aya projects into Roblox. Intends to support:

- Modular `.rbxl`s (a dependency can say, "put a remote named `JABBY_RELIABLE_REMOTE` in ReplicatedStorage")
- Rojo building and syncing

## Aya Pkg

Git-based package manager using require-by-string and allowing for integration with the rest of aya.
