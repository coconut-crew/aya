const luninjau = require("@pkg/luninjau")

const ninja_rules = {}

function ninja_rules.compile(): luninjau.NinjaStatRule
	return {
		stat = "rule",
		name = "compile",

		variables = {
			command = "aya c compile $in $out",
		},
	}
end

function ninja_rules.configure(): luninjau.NinjaStatRule
	return {
		stat = "rule",
		name = "configure",

		variables = {
			command = "aya c configure",
		},
	}
end

function ninja_rules.linkers(): luninjau.NinjaStatRule
	return {
		stat = "rule",
		name = "linkers",

		variables = {
			command = "aya c link $in $out",
		},
	}
end

function ninja_rules.compile_bin(): luninjau.NinjaStatRule
	return {
		stat = "rule",
		name = "compile_bin",

		variables = {
			command = "lute compile $in $out",
		},
	}
end

function ninja_rules.custom_command(): luninjau.NinjaStatRule
	return {
		stat = "rule",
		name = "custom_command",

		variables = {
			command = "$COMMAND",
		},
	}
end

return ninja_rules
