const log = require("@common/log")
const subcommand_ty = require("@common/subcommand_ty")
const process = require("@std/process")
const cli = require("@vendor/cli")

const subcommands: { [string]: subcommand_ty.Subcommand } = {
	compose = require("@compose"),
	pkg = require("@pkg"),
	make = require("@make"),
	test = require("@test"),
	install = require("@install"),
}

log.trace(`args: {table.concat(process.args, ", ")}`)

const raw_process_args = table.clone(process.args)

-- Remove executable
table.remove(raw_process_args, 1)

const parser = cli.parser()

parser:add("subcommand", "positional", {})

const subcommand_arg = raw_process_args[1]
const subcommand = subcommands[subcommand_arg]
if subcommand then
	subcommand.parser(parser)

	parser:parse(raw_process_args)

	subcommand.run(parser)
else
	print(parser:usage("aya"))
end
