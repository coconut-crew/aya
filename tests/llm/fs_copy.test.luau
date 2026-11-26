const fs = require("@std/fs")
const fs_copy = require("@src/common/utils/fs_copy")
const path = require("@std/path")
const process = require("@std/process")
const system = require("@std/system")
const test = require("@std/test")

const ROOT = path.join(system.tmpdir(), `aya_fs_copy_test_{process.pid()}`)

test.suite("fs_copy.file_or_directory", function(suite)
	suite:afterAll(function()
		if fs.exists(ROOT) then
			fs.removeDirectory(ROOT, { recursive = true })
		end
	end)

	suite:case("copies a directory into a destination inside itself once", function(t)
		const source = path.join(ROOT, "source")
		fs.createDirectory(path.join(source, "sub"), { makeParents = true })
		fs.writeStringToFile(path.join(source, "sub", "file.txt"), "hello")

		fs_copy.file_or_directory(source, path.join(source, "copy"))

		t.eq(fs.readFileToString(path.join(source, "copy", "sub", "file.txt")), "hello")
		t.eq(fs.exists(path.join(source, "copy", "copy")), false)
	end)
end)
