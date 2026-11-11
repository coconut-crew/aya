const anchors = require("@aya/common/anchors")
const buildsys = require("@aya/buildsys")
const cli_parser = require("@pkgs/cli_parser")
const pretty_print = require("@aya/common/utils/pretty_print")
const process = require("@std/process")

const cmd, tpath, positional = cli_parser.command, cli_parser.tpath, cli_parser.positional

const entry = cmd("root", function(cli)
	cmd("pkg", function(cli)
		cmd("install", function(cli) end).subcommandof(cli)
	end).subcommandof(cli)

	cmd("make", function(cli)
		cmd("configure", function(cli)
			tpath(cli.location)
			positional(cli, cli.location)
		end).subcommandof(cli)

		cmd("build", function(cli)
			tpath(cli.location)
			positional(cli, cli.location)
		end).subcommandof(cli)
	end).subcommandof(cli)

	cmd("bproc", function(cli)
		cmd("build", function(cli)
			tpath(cli.src)
			tpath(cli.dst)
		end).subcommandof(cli)

		cmd("regen", function(cli)
			tpath(cli.src)
		end).subcommandof(cli)

		cmd("discover_deps", function(cli)
			tpath(cli.src)
		end).subcommandof(cli)

		cmd("create_crate_links", function(cli)
			tpath(cli.crate)
		end).subcommandof(cli)
	end).subcommandof(cli)

	cmd("test", function(cli) end).subcommandof(cli)

	cli_parser.tails(cli, cli.xtask)
end)

const args = table.clone(process.args)
table.remove(args, 1)

const parsed = cli_parser.parse(entry, args)

anchors.set(process.cwd())

if parsed.bproc then
	if parsed.bproc.regen then
		buildsys.cmd_regen()
	end
end

pretty_print(parsed)
