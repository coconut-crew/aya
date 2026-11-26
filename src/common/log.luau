const colorful = require("@pkg/colorful")

const styles = colorful.styles
const grey = colorful.txt_colors.grey

const ERROR_INDICATOR = styles.err_indicator("  ERROR  ")
const WARN_INDICATOR = styles.warn_indicator("  WARN   ")
const INFO_INDICATOR = styles.info_indicator("  INFO   ")
const DEBUG_INDICATOR = styles.debug_indicator("  DEBUG  ")
const TRACE_INDICATOR = styles.trace_indicator("  TRACE  ")
const SUCCESS_INDICATOR = styles.success_indicator(" ✓ DONE  ")

const MESSAGE_INDENT = string.rep(" ", 21)

const function timestamp(): string
	return os.date("%H:%M:%S.") .. string.format("%.03d", math.round((os.clock() % 1) * 1000))
end

const function format_line(indicator: string, text: string): string
	const padded = string.gsub(text, "\n", "\n" .. MESSAGE_INDENT)
	return `{grey(timestamp())} {indicator} {padded}`
end

const function capture_stack_trace(depth: number): string
	return (
		string.gsub(debug.traceback(nil, depth), "[^\n]+", function(frame: string)
			const source, fn_name = string.match(frame, "^(.-) function (.+)$")
			const location = styles.stack_trace_text(source or frame)

			return `{MESSAGE_INDENT}{grey("at")} {grey(fn_name or "<anonymous>")} {location}`
		end)
	)
end

const log = {}

function log.err(text: string, level: number?)
	print(`{format_line(ERROR_INDICATOR, styles.err_text(text))}\n{capture_stack_trace(3)}`)
end

function log.warn(text: string)
	print(format_line(WARN_INDICATOR, styles.warn_text(text)))
end

function log.info(text: string)
	print(format_line(INFO_INDICATOR, styles.info_text(text)))
end

function log.success(text: string)
	print(format_line(SUCCESS_INDICATOR, styles.success_text(text)))
end

function log.dbg(text: string)
	print(format_line(DEBUG_INDICATOR, styles.debug_text(text)))
end

function log.trace(text: string)
	print(format_line(TRACE_INDICATOR, styles.trace_text(text)))
end

return table.freeze(log)
