const fs = require("@std/fs")
const manifest = require("@src/manifest")
const path = require("@std/path")
const process = require("@std/process")
const system = require("@std/system")
const test = require("@std/test")

const ROOT = path.join(system.tmpdir(), `aya_find_config_test_{process.pid()}`)

test.suite("manifest.find_closest_config", function(suite)
	suite:afterAll(function()
		if fs.exists(ROOT) then
			fs.removeDirectory(ROOT, { recursive = true })
		end
	end)

	suite:case("finds the manifest in an ancestor directory", function(t)
		const nested = path.join(ROOT, "a", "b", "c")
		fs.createDirectory(nested, { makeParents = true })
		fs.writeStringToFile(path.join(ROOT, manifest.CONFIG_FILE_NAME), "")

		const found = manifest.find_closest_config(nested)

		assert(found, "luau")
		t.eq(path.format(found), path.format(path.join(ROOT, manifest.CONFIG_FILE_NAME)))
	end)

	suite:case("walks above the working directory from a relative location", function(t)
		const nested = path.join(ROOT, "up", "deeper")
		fs.createDirectory(nested, { makeParents = true })
		fs.writeStringToFile(path.join(ROOT, "up", manifest.CONFIG_FILE_NAME), "")

		const ok, relative = pcall(path.relative, process.cwd(), nested)
		if not ok then
			-- the temp directory is on another drive than the working directory
			return
		end

		const found = manifest.find_closest_config(relative)

		assert(found, "luau")
		t.eq(path.format(found), path.format(path.join(ROOT, "up", manifest.CONFIG_FILE_NAME)))
	end)

	suite:case("stops at the filesystem root when nothing is found", function(t)
		const empty = path.join(ROOT, "empty")
		fs.createDirectory(empty, { makeParents = true })

		-- the temp directory is assumed to have no manifest above it
		const found = manifest.find_closest_config(empty)

		t.eq(
			found == nil
				or path.format(found)
					~= path.format(path.join(empty, manifest.CONFIG_FILE_NAME)),
			true
		)
	end)
end)
