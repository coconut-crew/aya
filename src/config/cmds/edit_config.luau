const config = require("@src/config")

export type Args = {
	read key: string?,
	read value: string?,
	read list: boolean?,
	read unset: boolean?,
}

const function edit_config(args: Args)
	if args.list then
		for key, value in config.read() :: { [string]: unknown } do
			print(`{key}={value}`)
		end

		return
	end

	const key = args.key
	assert(key, "usage: aya unset | value | list")

	if args.unset then
		config.unset(key)
	elseif args.value then
		config.set(key, args.value)
	else
		print(tostring(config.get(key)))
	end
end

return edit_config
