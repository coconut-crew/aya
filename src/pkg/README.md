# Package Model

## Packages

## Versions

- Semver is required
- Zero versions are treated differently: 0.2->0.3 is considered breaking, 0.2.1->0.2.2 is not considered breaking.

## Sources

- Sources are right now locked to github in the form of `<name> = { version = "0.1.0", github = "<author>" }`
- Private repos are supported
- (Needs fix) Dependencies with conflicting sources will error

# Internal Architecture

## Sources

## Resolver

## Lockfile

## Package Identifiers
