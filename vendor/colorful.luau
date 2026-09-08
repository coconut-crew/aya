const ANSI_16_FMT = `\027[%dm`

export type Styler = (text: string) -> string

const function create_styler_function(opener: number, closer: number): Styler
	const open = string.format(ANSI_16_FMT, opener)
	const close = string.format(ANSI_16_FMT, closer)

	const function styler(text: string)
		return open .. text .. close
	end

	return styler
end

const function combine_styles(style_array: { (text: string) -> string }): Styler
	const function txt(text: string)
		local result = text

		for _, style in style_array do
			result = style(result)
		end

		return result
	end

	return txt
end

return {
	combine_styles = combine_styles,

	modifier = {
		dim = create_styler_function(2, 22),
		reset = create_styler_function(0, 0),
		bold = create_styler_function(1, 22),
		italic = create_styler_function(3, 23),
		hidden = create_styler_function(8, 28),
		inverse = create_styler_function(7, 27),
		underline = create_styler_function(4, 24),
		overline = create_styler_function(53, 55),
		strikethrough = create_styler_function(9, 29),
	},

	color = {
		red = create_styler_function(31, 39),
		blue = create_styler_function(34, 39),
		cyan = create_styler_function(36, 39),
		gray = create_styler_function(90, 39),
		grey = create_styler_function(90, 39),
		black = create_styler_function(30, 39),
		green = create_styler_function(32, 39),
		white = create_styler_function(37, 39),
		yellow = create_styler_function(33, 39),
		magenta = create_styler_function(35, 39),
		red_bright = create_styler_function(91, 39),
		blue_bright = create_styler_function(94, 39),
		cyan_bright = create_styler_function(96, 39),
		black_bright = create_styler_function(90, 39),
		green_bright = create_styler_function(92, 39),
		white_bright = create_styler_function(97, 39),
		yellow_bright = create_styler_function(93, 39),
		magenta_bright = create_styler_function(95, 39),
	},
}
