const installation = require("@self/installation")
const manifest = require("@self/manifest")
const path = require("@std/path")

const project_manifest = manifest.read(path.parse("./ayapkg.toml"))

installation.install_dependencies(project_manifest)
