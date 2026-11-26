const build = require("@src/build/cmds/build")
const cli_parser = require("@pkg/cli_parser")
const configure = require("@src/build/cmds/configure")
const edit_config = require("@src/config/cmds/edit_config")
const install = require("@src/pkg/cmds/install")
const process = require("@std/process")

const cmd, flag, positional, tpath =
	cli_parser.command, cli_parser.flag, cli_parser.positional, cli_parser.tpath

const function add_help(cli)
	flag(cli.help, { "h" })
	cli.help.helpline = "prints information relating to this command"
end

const function cli(args: { string })
	const entry = cmd("aya", function(cli)
		add_help(cli)

		cmd("pkg", function(cli)
			add_help(cli)

			cmd("install", function(cli)
				add_help(cli)
				tpath(cli.workspace, { "w" })
			end).subcommandof(cli)
		end).subcommandof(cli)

		cmd("make", function(cli)
			add_help(cli)

			cmd("build", add_help).subcommandof(cli)
			cmd("configure", add_help).subcommandof(cli)
		end).subcommandof(cli)

		cmd("config", function(cli)
			add_help(cli)
			flag(cli.list, { "l" })
			flag(cli.unset)
			positional(cli, cli.key, cli.value)
		end).subcommandof(cli)
	end)

	const parsed = cli_parser.parse(entry, args)
	const help_config = cli_parser.help_config()

	--[[
		ai-generated. help screen annoying
	]]
	const pkg = parsed.pkg
	if pkg then
		const pkg_install = pkg.install
		if pkg_install and not pkg_install.help then
			install(pkg_install.workspace or process.cwd())
		end

		print(
			cli_parser.help_screen(
				if pkg_install then entry.pkg.install else entry.pkg,
				help_config
			)
		)
		return
	end

	const make = parsed.make
	if make then
		if make.build and not make.build.help then
			build()
		elseif make.configure and not make.configure.help then
			configure()
		else
			print(cli_parser.help_screen(entry.make, help_config))
		end

		return
	end

	const config_args = parsed.config
	if config_args then
		if config_args.help or not (config_args.list or config_args.key) then
			print(cli_parser.help_screen(entry.config, help_config))
		else
			edit_config(config_args)
		end

		return
	end

	print(cli_parser.help_screen(entry, help_config))
end

return cli
