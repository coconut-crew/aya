const luau_config = {
	languagemode = `strict`,

	aliases = {
		std = "~/.lute/typedefs/1.0.1/std",
		lute = "~/.lute/typedefs/1.0.1/lute",
		vendor = "./vendor",

		aya = "./aya",
		pkgs = "./pkgs/links",
	},

	lint = {
		[`*`] = true,
	},
}

return {
	luau = luau_config,
}
