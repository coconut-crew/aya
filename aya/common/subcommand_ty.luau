const cli = require("@vendor/cli")

export type Subcommand = {
	parser: (parser: cli.Parser) -> (),
	run: (parser: cli.Parser) -> (),
}

return nil
