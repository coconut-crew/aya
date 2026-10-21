const luau_config = {
	languagemode = `strict`,

	aliases = {
		std = "~/.lute/typedefs/1.0.1/std",
		lute = "~/.lute/typedefs/1.0.1/lute",
		vendor = "./vendor",
		["aya-common"] = "./aya/common",
		["aya-compose"] = "./aya/compose",
		["aya-init"] = "./aya/install",
		["aya-make"] = "./aya/make",
		["aya-pkg"] = "./aya/pkg",
		["aya-test"] = "./aya/test",
		["aya-installation"] = "./aya/installation",
		pkgs = "./pkgs/links",
	},

	lint = {
		[`*`] = true,
	},
}

return {
	luau = luau_config,
}
