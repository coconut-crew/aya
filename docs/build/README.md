# Example manifest

```toml
[workspace.dependencies]
lints = { version = "0.1.0", github = "coconut-crew" }

[package]
name = "content_management"
version = "0.1.0"

[package.dependencies]
log = { version = "0.1.0", github = "coconut-crew" }

[package.bin]
obfuscate = {}

[crate.server]
[crate.server.meta]
[crate.server.bin]
[crate.server.src]
```
