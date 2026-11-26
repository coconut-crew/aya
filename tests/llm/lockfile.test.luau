const fs = require("@std/fs")
const lockfile = require("@src/pkg/lockfile")
const path = require("@std/path")
const process = require("@std/process")
const semver = require("@src/pkg/utils/semver")
const system = require("@std/system")
const test = require("@std/test")

-- sha256 of no bytes, the checksum of an empty directory's summary
const CHECKSUM = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

const function locked_package(version: string): lockfile.Package
	return { version = semver.parse(version), checksum = CHECKSUM }
end

test.suite("lockfile.parse", function(suite)
	suite:case("reads back what serialize writes", function(t)
		const locked: lockfile.Identity = {
			a = locked_package("1.2.0"),
			b = locked_package("0.3.1-beta.2"),
		}

		t.eq(lockfile.parse(lockfile.serialize(locked)), locked)
		t.eq(lockfile.parse(lockfile.serialize({})), {})
	end)

	suite:case("rejects an unsupported lockfile version", function(t)
		t.throwsWith(
			"unsupported lockfile version 2, expected 1",
			lockfile.parse,
			"lockfile_version: 2\n"
		)
		t.throwsWith(
			"unsupported lockfile version nil, expected 1",
			lockfile.parse,
			"packages: {}\n"
		)
	end)

	suite:case("rejects a lockfile that is not a mapping", function(t)
		t.throwsWith("the lockfile must be a mapping", lockfile.parse, "")
		t.throwsWith("the lockfile must be a mapping", lockfile.parse, "just text")
	end)

	suite:case("rejects malformed packages", function(t)
		t.throwsWith("packages must be a mapping", lockfile.parse, "lockfile_version: 1\n")
		t.throwsWith(
			"locked package names must be strings",
			lockfile.parse,
			"lockfile_version: 1\npackages:\n  - a\n"
		)
		t.throwsWith(
			"a: the locked package must be a mapping",
			lockfile.parse,
			"lockfile_version: 1\npackages:\n  a: 1.0.0\n"
		)
		t.throwsWith(
			"a: version must be a string",
			lockfile.parse,
			"lockfile_version: 1\npackages:\n  a: {}\n"
		)
		t.throwsWith(
			"a: checksum must be a string",
			lockfile.parse,
			"lockfile_version: 1\npackages:\n  a: { version: 1.0.0 }\n"
		)
	end)
end)

test.suite("lockfile.read and lockfile.write", function(suite)
	suite:case("round trips through a directory, and reads nothing without a lockfile", function(t)
		const dir = path.join(system.tmpdir(), `aya_lockfile_test_{process.pid()}`)
		fs.createDirectory(dir)

		t.eq(lockfile.read(dir), nil)

		const locked: lockfile.Identity = { a = locked_package("1.0.0") }
		lockfile.write_async(locked, dir)

		t.eq(lockfile.read(dir), locked)
		fs.removeDirectory(dir, { recursive = true })
	end)
end)

test.suite("lockfile.identifiers", function(suite)
	suite:case("names each locked version", function(t)
		t.eq(
			lockfile.identifiers({
				a = locked_package("1.0.0"),
				b = locked_package("2.1.0-rc.1"),
			}),
			{ ["a@1.0.0"] = true, ["b@2.1.0-rc.1"] = true }
		)
	end)
end)
