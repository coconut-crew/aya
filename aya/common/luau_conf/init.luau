const log = require("@common/log")
const fs = require("@std/fs")
const luau = require("@std/luau")
const path = require("@std/path")
const process = require("@std/process")

const luau_conf = {}
luau_conf.__index = luau_conf
export type Identity<T> = setmetatable<{
	ctx_constructor: (path.Path) -> T,
	fns: { [string]: (ctx: T, ...unknown) -> () },
	globals: { [string]: string | number | boolean },
}, typeof(luau_conf)>

const function constructor<T>(ctx_constructor: (path.Path) -> T): Identity<T>
	const self = setmetatable({
		ctx_constructor = ctx_constructor,
		fns = {},
		globals = {},
	}, luau_conf)

	return self
end

function luau_conf.add_function<T>(self: Identity<T>, fn_name: string, fn_body: (ctx: T, ...unknown) -> ())
	self.fns[fn_name] = fn_body
end

function luau_conf.add_global<T>(self: Identity<T>, global: string, value: string | number | boolean)
	self.globals[global] = value
end

function luau_conf.file<T>(self: Identity<T>, conf_path: path.Path): T
	const ctx = self.ctx_constructor(conf_path)

	const env: { [string]: any } = {
		pcall = pcall,

		math = math,
		os = os,
		bit32 = bit32,
		utf8 = utf8,
		table = table,
		string = string,

		error = error,
		print = print,

		tostring = tostring,
		tonumber = tonumber,

		ipairs = ipairs,
		pairs = pairs,

		unpack = unpack,
	}

	for fn_name, fn_body in self.fns do
		env[fn_name] = function(...: unknown)
			fn_body(ctx, ...)
		end
	end

	for global_name, global_value in self.globals do
		env[global_name] = global_value
	end

	const file_content = fs.readFileToString(conf_path)
	const bytecode = luau.compile(file_content)

	const fn = luau.load(bytecode, "aya-make", env)

	const thread = coroutine.create(fn)

	const ok = coroutine.resume(thread)
	if ok then
		log.info(`ran {conf_path} successfully`)
	else
		log.warn(`{conf_path} errored, halting execution`)
		print(debug.traceback(thread))
		process.exit(1)
	end

	return ctx
end

table.freeze(luau_conf)
return { new = constructor }
