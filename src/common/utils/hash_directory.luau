--[[
	AI generated implementation
]]

const crypto = require("@lute/crypto")
const fs = require("@std/fs")
const path = require("@std/path")
const to_hex = require("@src/common/utils/to_hex")

const function sha256_hex(content: string): string
	return string.lower(to_hex.string(crypto.digest(crypto.hash.sha256, content)))
end

-- relative paths use "/" on every platform, so the hash doesn't depend on where it was computed
const function collect_files(dir: path.Pathlike, prefix: string, into: { string })
	for _, entry in fs.listDirectory(dir) do
		const relative = prefix .. entry.name
		if entry.type == "dir" then
			collect_files(path.join(dir, entry.name), relative .. "/", into)
		else
			table.insert(into, relative)
		end
	end
end

--[[
	sha256 of a summary with one "<sha256 of file>  <relative path>" line per file, sorted by path.
	this is the construction go's dirhash uses for go.sum. empty directories don't affect it
]]
const function hash_directory(dir: path.Pathlike): string
	const files: { string } = {}
	collect_files(dir, "", files)
	table.sort(files)

	const lines: { string } = {}
	for _, relative in files do
		assert(
			not string.find(relative, "\n", 1, true),
			"cannot hash a file name containing a newline"
		)

		const content = fs.readFileToString(path.join(dir, relative))
		table.insert(lines, `{sha256_hex(content)}  {relative}\n`)
	end

	return sha256_hex(table.concat(lines))
end

return hash_directory
