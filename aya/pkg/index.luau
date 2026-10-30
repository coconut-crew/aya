const fs = require("@std/fs")
const installation = require("@aya-installation")
const path = require("@std/path")

const pkg_dir = installation.register_dir("pkg")

const index = {}

function index.load()
	if fs.exists(fs.readFileToString(path.join(pkg_dir, "index"))) then
	end
end

function index.find(author: string?, name: string?) end

return table.freeze(index)
