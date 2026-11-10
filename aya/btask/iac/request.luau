const auth = require("./auth")
local json = require("@vendor/json")
const net = require("@std/net")
const styles = require("../styles")
const task = require("@std/task")

local request = {}

type CommonContentTypes = "application/json" | "application/octet-stream" | string

function request.request(
	method: "POST" | "GET" | "PATCH" | "DELETE" | string,
	url: string,
	body: string,
	headers: { ["Content-Type"]: CommonContentTypes, [string]: string },

	query: { [string]: string }?,
	use_cookie: boolean?
)
	if use_cookie then
		headers["Cookie"] = `.ROBLOSECURITY={auth.get_roblox_cookie()}`
		headers["x-csrf-token"] = auth.get_csrf_token()
	else
		headers["x-api-key"] = auth.get_open_key()
	end

	headers["User-Agent"] = "lute iac tool"

	if query and next(query) then
		local list = {}
		for key, value in query do
			table.insert(list, `{key}={value}`)
		end
		url = `{url}?{table.concat(list, "?")}`
	end

	const response = net.request(url, {
		method = method,
		body = body,
		headers = headers,
	})

	if response.ok then
		if response.headers["Set-Cookie"] then
			const new_cookie = response.headers["Set-Cookie"]
			auth.update_roblox_cookie(new_cookie)
		end

		const rate_limit_remaining = tonumber(response.headers["x-ratelimit-remaining"])
		const ratelimit_reset_when = response.headers["x-ratelimit-reset"]

		if rate_limit_remaining ~= nil and rate_limit_remaining <= 1 then
			print(styles.warning(`request quota for {url} has been reached. yielding before continuing to reset quota.`))
			task.wait(tonumber(ratelimit_reset_when))
		end
	end

	return response
end

return request
