const cli = require("@aya/cli")
const process = require("@std/process")

const args = table.clone(process.args)
table.remove(args, 1)

cli(args)
