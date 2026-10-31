const cli = require("@vendor/cli")
const process = require("@std/process")
const subcommand_ty = require("@aya-common/subcommand_ty")
const text_styling = require("@aya-common/text_styling")

const subcommand_map: { [string]: subcommand_ty.Subcommand } = {
	pkg = require("@aya-pkg"),
	make = require("@aya-make"),
}

const function usage()
	print(text_styling.header("Usage"))
	print(text_styling.info("aya [subcommand]"))
	print("")
	print(text_styling.header("Subcommands"))
	print("\t- pkg")
	print("\t- make")
	print("\t- compose")
	print("\t- test")
	print("\t- init")
	print(text_styling.header("Options"))
	print("\t`-v` or `--verbose`: Increase verbosity")
end

const args = table.clone(process.args)

const arg_program = table.remove(args, 1)
assert(arg_program, "const")

const arg_subcommand_picked = table.remove(args, 1)
assert(arg_subcommand_picked, "subcommand always exists")

const subcommand_picked = subcommand_map[arg_subcommand_picked]
if not subcommand_picked then
	usage()
	return
end

subcommand_picked.run(args)
