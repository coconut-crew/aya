# Phases

## Configure

- [ ] Writes `.config.luau`s in each crate
- [ ] Runs on any `.aya.toml` file changes
- [ ] Builds tasks
- [ ] Creates linker files

## Build

- [ ] runs build.luau files, implements hooks
- [ ] runs transformers

# Exposed commands

## `aya build`

## `aya configure`

# Build commands

## `aya bcmd link`

## `aya bcmd compile`

## `aya bcmd transform`

# Build pipeline

- hook-based
- build scripts are required to be idempotent: they cannot have any side effects on require
    - i love distributed systems

## chronological ordering

**configure step:**

1. invoke build scripts
2. build map of hooks and which scripts invoke those hooks?

**build time:**

1.
