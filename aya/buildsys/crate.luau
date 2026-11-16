const anchors = require("@aya/common/anchors")
const fs = require("@std/fs")
const generate_linker_file = require("@aya/common/generate_linker_file")
const generate_uuid = require("@aya/common/utils/generate_uuid")
const json = require("@vendor/json")
const luninjau = require("@pkgs/luninjau")
const path = require("@std/path")
const pretty_print = require("@aya/common/utils/pretty_print")
const process = require("@std/process")
const tys = require("@aya/buildsys/tys")

const crate = {}

function crate.build_path_of(self: tys.Crate)
	return path.join(anchors.build(), "out", self.package, self.name)
end

function crate.src_path_of(self: tys.Crate)
	path.join(anchors.build(), "src", self.package, self.name)
end

return table.freeze(crate)
