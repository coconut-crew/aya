const INDENT = `   `
const DEFAULT_PRETTY_PRINT_DECIMALS = 4
-- scientific notation is in base 10, this is the closest power of 10 above 2^53 which is the max integer an f64 (luau
-- number) can accurately represent.
const SCIENTIFIC_NOTATION_THRESHOLD = 10 ^ 16

const colorful = require(`@vendor/colorful`)

const color = colorful.color
const modifier = colorful.modifier

const brightblue, cyan, grey, magenta, underline = color.blue_bright, color.cyan, color.grey, color.magenta, modifier.underline

type UnknownTbl = { [unknown]: unknown }

local pretty_print_digits_precision = 4
local indent_print
local pretty_print_from_precision
local _pretty_print
local indent_newlines
local pretty_print_nil
local pretty_print_str
local pretty_print_tbl
local pretty_print_bool
local pretty_print_func
local pretty_print_number
local pretty_print_thread
local pretty_print_vector
local pretty_print_unknown
local pretty_print_from_epsilon

function indent_newlines(str: string): string
	const indented = string.gsub(str, `\n`, `\n{INDENT}`)
	return indented
end

function indent_print(input: unknown): string
	return indent_newlines(_pretty_print(input))
end

do
	local comma_value
	function pretty_print_number(num: number): string
		const string_format = string.format

		local as_str: string

		if num >= SCIENTIFIC_NOTATION_THRESHOLD then
			const formatted_round = string_format(`%.{pretty_print_digits_precision}e`, num)

			as_str = formatted_round
		else
			const remainder = num % (10 ^ -pretty_print_digits_precision)
			const rounded = num - remainder

			as_str = comma_value(rounded)
		end

		return brightblue(as_str)
	end
	function comma_value(amount: number): string
		-- radix matches can be 0 or 1, because the match is greedy and anchored to the beginning of the string.
		-- once it's zero, there are no more groups of three digits to separate by comma.
		local formatted, radix_matches = string.gsub(tostring(amount), `^(%d+)(%d%d%d)`, `%1,%2`)
		while radix_matches ~= 0 do
			formatted, radix_matches = string.gsub(formatted, `^(%d+)(%d%d%d)`, `%1,%2`)
		end
		return formatted
	end
end

function pretty_print_str(str: string): string
	if string.match(str, `\n`) then
		return magenta(`[[\n`) .. indent_newlines(str) .. magenta(`\n]]`) --
	end
	return `{magenta(`"`)}{brightblue(str)}{magenta(`"`)}`
end

function pretty_print_nil(nothing: nil): string
	return brightblue(underline(`nil`))
end

function pretty_print_bool(bool: boolean): string
	return brightblue(underline(`{bool}`))
end

function pretty_print_vector(vector: vector): string
	return `vector`
		.. magenta(`<`)
		.. pretty_print_number(vector.x)
		.. `, {pretty_print_number(vector.y)}`
		.. `, {pretty_print_number(vector.z)}`
		.. magenta(`>`)
end

function pretty_print_func<Params..., Returns...>(func: (Params...) -> Returns...): string
	const address = string.gsub(tostring(func), `.* `, ``)

	const name = debug.info(func, `n`)

	if (name == nil) or (name == ``) then
		return magenta(`<`) .. `function ({address})` .. magenta(`>`)
	else
		return magenta(`<`) .. `function "{name}" ({address})` .. magenta(`>`)
	end
end

function pretty_print_thread(thread: thread): string
	const status = string.upper(coroutine.status(thread))

	local output = magenta(`<`) .. `{tostring(thread)} {status} @ ` .. magenta(`[`)

	output ..= indent_newlines(`\n{debug.traceback(thread)}`)

	-- weird hack to remove ending newline
	output = string.gsub(output, `\n{INDENT}$`, ``)

	output ..= `\n` .. magenta(`]`) .. magenta(`>`)

	return output
end

function pretty_print_tbl(tbl: UnknownTbl): string
	local output = magenta(`\{\n`)

	for key, value in tbl do
		output ..= `{INDENT}{cyan(`[`)}{indent_print(key)}{cyan(`]`)} = {indent_print(value)}\n`
	end

	output ..= magenta(`}`)

	return output
end

function pretty_print_unknown(value: unknown): string
	const typeof_value = typeof(value)

	-- remove any potential interfering beginning/ending chevrons
	local stringified = string.gsub(string.gsub(tostring(value), `^<`, ``), `>$`, ``)

	-- if value's tostring contains its type, don't include it in the stringification
	if string.match(string.lower(stringified), string.lower(typeof_value)) then
		stringified = magenta(`<`) .. grey(stringified) .. magenta(`>`)
	else
		stringified = magenta(`<`) .. grey(`{typeof_value}: {stringified}`) .. magenta(`>`)
	end

	return stringified
end

function _pretty_print(value: any): string
	if type(value) == `number` then
		return pretty_print_number(value)
	elseif type(value) == `string` then
		return pretty_print_str(value)
	elseif type(value) == `nil` then
		return pretty_print_nil(value)
	elseif type(value) == `boolean` then
		return pretty_print_bool(value)
	elseif type(value) == `vector` then
		return pretty_print_vector(value)
	elseif type(value) == `function` then
		return pretty_print_func(value :: (...any) -> ...any)
	elseif type(value) == `thread` then
		return pretty_print_thread(value)
	elseif type(value) == `table` then
		return pretty_print_tbl(value :: UnknownTbl)
	end
	return pretty_print_unknown(value)
end

function pretty_print_from_precision(value: any, digits_precision: number?): string
	if not digits_precision then
		return _pretty_print(value)
	end

	pretty_print_digits_precision = digits_precision
	const output = _pretty_print(value)
	pretty_print_digits_precision = DEFAULT_PRETTY_PRINT_DECIMALS

	return output
end

function pretty_print_from_epsilon(value: any, epsilon: number?): string
	if not epsilon then
		return _pretty_print(value)
	end

	pretty_print_digits_precision = if epsilon >= 1 then 0 else math.ceil(math.clamp(-math.log10(epsilon), 0, 100))
	const output = _pretty_print(value)
	pretty_print_digits_precision = DEFAULT_PRETTY_PRINT_DECIMALS

	return output
end

const function indent(str: string): string
	return `{INDENT}{string.gsub(str, `\n`, INDENT)}`
end

local api = {
	from_precision = pretty_print_from_precision,
	from_epsilon = pretty_print_from_epsilon,
	indent_newlines = indent_newlines,
	indent = indent,
}

setmetatable(api :: any, {
	__call = function(_, value: any)
		local txt = pretty_print_from_epsilon(value)
		print(txt)
		return txt
	end,
})

return (api :: any) :: typeof(api) & (value: any) -> string
