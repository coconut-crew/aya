const cli = require("@vendor/cli")

export type Subcommand = {
	description: string?,
	run: ({ string }) -> (),
}

return nil
