const luau_config = {
	languagemode = `strict`,

	aliases = {
		lune = "~/.lune/.typedefs/0.10.5/",
		std = "~/.lute/typedefs/1.0.1/std",
		vendor = "./vendor",
		common = "./aya/common",
		compose = "./aya/compose",
		install = "./aya/install",
		make = "./aya/make",
		pkg = "./aya/pkg",
		test = "./aya/test",
	},

	lint = {
		[`*`] = true,
	},
}

return {
	luau = luau_config,
}
