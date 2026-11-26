const cli_parser = require("@pkg/cli_parser")
const process = require("@std/process")

const cmd, tpath, positional = cli_parser.command, cli_parser.tpath, cli_parser.positional

const function cli(args: { string })
	const entry = cmd("root", function(cli)
		cmd("pkg", function(cli) end)

		cmd("make", function(cli) end)
	end)

	const parsed = cli_parser.parse(entry, args)
end

return cli
