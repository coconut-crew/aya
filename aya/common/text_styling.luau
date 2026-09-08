const colorful = require("@vendor/colorful")

return {
	failure = colorful.combine_styles({ colorful.color.red_bright }),
	info = colorful.combine_styles({ colorful.color.blue }),
	header = colorful.combine_styles({ colorful.color.white_bright, colorful.modifier.bold }),
	trace = colorful.combine_styles({ colorful.color.white_bright, colorful.modifier.dim }),
	success = colorful.combine_styles({ colorful.color.green_bright, colorful.modifier.bold }),
	warn = colorful.combine_styles({ colorful.color.yellow }),
	separator = colorful.combine_styles({ colorful.color.grey, colorful.modifier.dim, colorful.modifier.bold }),
	readable = colorful.combine_styles({ colorful.color.white_bright }),
	stack_trace = colorful.combine_styles({ colorful.color.blue, colorful.modifier.dim }),
}
