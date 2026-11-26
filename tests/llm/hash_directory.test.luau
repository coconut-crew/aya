const fs = require("@std/fs")
const hash_directory = require("@src/common/utils/hash_directory")
const path = require("@std/path")
const process = require("@std/process")
const system = require("@std/system")
const test = require("@std/test")

const ROOT = path.join(system.tmpdir(), `aya_hash_directory_test_{process.pid()}`)

-- { [relative path with "/"]: file content }
const function make_tree(name: string, files: { [string]: string }): path.Path
	const dir = path.join(ROOT, name)
	fs.createDirectory(dir, { makeParents = true })

	for relative, content in files do
		const parts = string.split(relative, "/")
		if #parts > 1 then
			fs.createDirectory(
				path.join(dir, table.concat(parts, "/", 1, #parts - 1)),
				{ makeParents = true }
			)
		end

		fs.writeStringToFile(path.join(dir, relative), content)
	end

	return dir
end

test.suite("hash_directory", function(suite)
	suite:afterEach(function()
		if fs.exists(ROOT) then
			fs.removeDirectory(ROOT, { recursive = true })
		end
	end)

	suite:case("hashes an empty directory as the sha256 of an empty summary", function(t)
		t.eq(
			hash_directory(make_tree("empty", {})),
			"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
		)
	end)

	suite:case("matches go's dirhash summary for a known tree", function(t)
		-- sha256 of "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824  a.txt\n"
		const expected = "c703ac0c3c578e7bc50eba0089746631b24582f42bedd483e3b4b9336210654d"

		t.eq(hash_directory(make_tree("known", { ["a.txt"] = "hello" })), expected)
	end)

	suite:case("gives the same hash to the same files", function(t)
		const files =
			{ ["a.luau"] = "return 1", ["src/b.luau"] = "return 2", ["src/deep/c.txt"] = "c" }

		t.eq(hash_directory(make_tree("one", files)), hash_directory(make_tree("two", files)))
	end)

	suite:case("changes when a file's content changes", function(t)
		t.neq(
			hash_directory(make_tree("one", { ["a.luau"] = "return 1" })),
			hash_directory(make_tree("two", { ["a.luau"] = "return 2" }))
		)
	end)

	suite:case("changes when a file is renamed or moved", function(t)
		const original = hash_directory(make_tree("original", { ["a.luau"] = "x" }))

		t.neq(hash_directory(make_tree("renamed", { ["b.luau"] = "x" })), original)
		t.neq(hash_directory(make_tree("moved", { ["src/a.luau"] = "x" })), original)
	end)

	suite:case("ignores empty directories", function(t)
		const files = { ["a.luau"] = "x" }
		const with_empty = make_tree("with_empty", files)
		fs.createDirectory(path.join(with_empty, "empty"))

		t.eq(hash_directory(with_empty), hash_directory(make_tree("without", files)))
	end)
end)
