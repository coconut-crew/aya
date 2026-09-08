const luau_config = {
	languagemode = `strict`,

	aliases = {
		src = "./src/",
	},

	lint = {
		[`*`] = true,
	},
}

return {
	luau = luau_config,
}
