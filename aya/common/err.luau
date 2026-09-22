const task = require("@std/task")

export type Dbg = {
	thread: thread,

	source_path: string,
	line: number,
	fn_name: string,
	fn: (...unknown) -> ...unknown,

	trace: string,
}

export type Err = {
	code: string,
	msg: string,

	retryable: boolean,

	dbg: Dbg,
}

export type Res<T> =
	{
		ok: true,
		ret: T,
	}
	| {
		ok: false,
		err: Err,
	}

const err = {}

function err.emit() end

function err.safecall<R, U...>(func: (U...) -> R, ...: U...): Res<R>
	const thread = task.spawn(func, ...)

	const status = coroutine.status(thread)
	if status == "dead" then
	end
end

return err
