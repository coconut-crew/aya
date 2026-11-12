const anchors = require("@aya/common/anchors")
const crate = require("@aya/buildsys/crate")
const fs = require("@std/fs")
const generate_uuid = require("@aya/common/utils/generate_uuid")
const path = require("@std/path")
const pretty_print = require("@aya/common/utils/pretty_print")
const system = require("@std/system")
const test = require("@std/test")

const function make_crate(dir: path.Pathlike): crate.Identity
	return {
		name = "core",
		dir = dir,
		exports = {},
		needs = {},
	}
end

local workspace: path.Path

const function setup_workspace()
	table.clear(crate.uuid_map)

	workspace = path.join(system.tmpdir(), `aya-crate-test-{generate_uuid()}`)
	anchors.set(workspace)
	fs.createDirectory(anchors.build(), { makeParents = true })
end

const function remove_workspace()
	table.clear(crate.uuid_map)
	fs.removeDirectory(workspace, { recursive = true })
end

test.suite("crate cratemap", function(suite)
	suite:beforeEach(setup_workspace)
	suite:afterEach(remove_workspace)

	suite:case("restores every crate uuid after an export and import", function(t)
		crate.uuid_map[path.format(path.parse("crates/core"))] = generate_uuid()
		crate.uuid_map[path.format(path.parse("packages/ui/widgets"))] = generate_uuid()
		const expected = table.clone(crate.uuid_map)

		crate.export_uuids_async()
		table.clear(crate.uuid_map)
		crate.import_uuids_async()

		t.eq(crate.uuid_map, expected)
	end)

	suite:case("imports nothing from an exported empty map", function(t)
		crate.export_uuids_async()
		crate.import_uuids_async()

		t.eq(crate.uuid_map, {})
	end)
end)

test.suite("crate.uuid_async", function(suite)
	suite:beforeEach(setup_workspace)
	suite:afterEach(remove_workspace)

	suite:case("returns the stored uuid for a crate already in the map", function(t)
		const uuid = generate_uuid()
		crate.uuid_map[path.format(path.parse("crates/core"))] = uuid

		t.eq(crate.uuid_async(make_crate(path.parse("crates/core"))), uuid)
	end)

	suite:case("finds the stored uuid whether dir is a string or a parsed path", function(t)
		crate.uuid_map[path.format(path.parse("crates/core"))] = generate_uuid()

		t.eq(crate.uuid_async(make_crate("crates/core")), crate.uuid_async(make_crate(path.parse("crates/core"))))
	end)
end)

test.case("generate_uuid returns a different value on each call", function(t)
	t.neq(generate_uuid(), generate_uuid())
end)
