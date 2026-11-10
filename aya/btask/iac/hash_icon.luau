const crypto = require("@lute/crypto")
const fs = require("@std/fs")
const path = require("@std/path")
const to_hex = require("./to_hex")

local hash_icon = {}

function hash_icon.hash(path: path.Pathlike)
	const icon = fs.readFileToString(path)
	const hash = to_hex.string(crypto.digest(crypto.hash.md5, icon))

	return hash
end

return hash_icon
