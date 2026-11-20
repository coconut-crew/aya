const luninjau = require("@pkg/luninjau")

const ninja_rules = {}

function ninja_rules.compile(): luninjau.NinjaStatRule
	return {
		stat = "rule",
		name = "compile",

		variables = {
			command = "aya c compile $in $out --workspace $AYA_WORKSPACE",
		},
	}
end

function ninja_rules.configure(): luninjau.NinjaStatRule
	return {
		stat = "rule",
		name = "configure",

		variables = {
			command = "aya c configure --workspace $AYA_WORKSPACE",
		},
	}
end

function ninja_rules.linkers(): luninjau.NinjaStatRule
	return {
		stat = "rule",
		name = "linkers",

		variables = {
			command = "aya c link $in $out --workspace $AYA_WORKSPACE",
		},
	}
end

return ninja_rules
