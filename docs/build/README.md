# Example manifest

```toml
[package]
name = "content_management"
version = "0.1.0"

[package.dependencies]
log = { version = "0.1.0", github = "coconut-crew" }

[workspace.dependencies]
lints = { version = "0.1.0", github = "coconut-crew" }

[crates.server]
dir = "src/server"
exports = [
	"api/**"
]
needs = [
	"log/server"
]

[crates.shared]
dir = "src/shared"
exports = [
	"api/**"
]
needs = [
	"log/shared"
]
```
