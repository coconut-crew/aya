# aya-pkg

handles packages

## commands

### install

installs all the required packages defined by an ayapkg.toml; this occurs somewhat recursively.

## dependency types

### git

git dependencies can depend on other git dependencies as well as path dependencies within the repository.

### path

path dependencies can depend on other dependencies as well. this is also how you define relationships within a monorepo

## monorepo

monorepo support can be enabled by creating an ayapkg.toml in your root and setting `monorepo = true` as well as defining a glob for where all your packages are stored.
