const anchors = require("@aya/common/anchors")
const path = require("@std/path")

const dir = {}

function dir.out(): path.Pathlike
	return path.join(anchors.build(), "out")
end

function dir.linkers(): path.Pathlike
	return path.join(anchors.build(), "linkers")
end

return table.freeze(dir)
