Human written file btw sorry if i speak like LLM im just tryna plan shit out

# Feature list

## Abstract

- Dynamic dependencies in every way
- Support all kinds of workflows and preprocessors
- Peak modularity
- Incremental compilation to make editing games fast.
- Support integrations
- Compile commands

## Build files

## Graph

- Dynamically discovered source files. The require graph builds a list of source files which gets used later.
- Dynamically discovered library dependencies. Requires can introduce entire sections of build systems. Requiring a file which needs additional processing will cause that processing to be introduced into the build system without any configuration needing to happen.

### The tradeoffs

Incremental compilation is significantly slower as a result of all these features. That's okay, I'm willing to throw more money at github actions or self-host it.

#

## Build graph

## Utility components

- `regen`
- `scan`
- `build`

## File structure
