const colorful = require("@vendor/colorful")
const text_styling = require("./text_styling")

export type Verbosity = "quiet" | "normal" | "loud"

const function timestamp(): string
	return os.date("%H:%M:%S.") .. string.format("%.03d", math.floor((os.clock() % 1) * 1000))
end

const log = {
	verbosity = "loud" :: Verbosity,
}

function log.warn(txt: string)
	print(
		text_styling.warn(
			colorful.modifier.bold(`[{timestamp()}] [WARN] `)
				.. text_styling.readable(txt)
				.. "\n"
				.. text_styling.stack_trace(
					`\t{debug.info(2, "s")}:{debug.info(2, "l")}`
						.. if debug.info(2, "n") ~= "" then ` {debug.info(2, "n")}` else "" .. "\n"
				)
		)
	)
end

function log.info(txt: string)
	print(text_styling.info(`[{timestamp()}] [INFO] {text_styling.readable(txt)}`))
end

function log.trace(txt: string)
	print(text_styling.trace(`[{timestamp()}] [TRACE] {txt}`))
end

return log
