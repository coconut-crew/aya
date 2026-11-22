const crate = require("@src/build/crate")
const path = require("@std/path")

const luau_object = {}

function luau_object.id(crate_id: crate.CrateName, file: path.Pathlike) end

return table.freeze(luau_object)
