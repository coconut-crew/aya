const installation = require("@aya-pkg/installation")
const manifest = require("@aya-pkg/manifest")
const path = require("@std/path")
const process = require("@std/process")

const project_manifest = manifest.read(path.join(process.cwd(), "ayapkg.toml"))

installation.install_dependencies(project_manifest)
