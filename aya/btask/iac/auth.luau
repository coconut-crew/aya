const fs = require("@std/fs")
const net = require("@std/net")
const styles = require("../styles")

local security_cookie: false | string = false
local csrf_token: false | string = false

const auth = {}

function auth.get_iac_key()
	return string.gsub(fs.readFileToString("./secrets/iac-taro-api"), "%s+$", "")
end

function auth.get_open_key()
	return string.gsub(fs.readFileToString("./secrets/iac-api-key"), "%s+$", "")
end

function auth.pull_security_cookie(): string
	const cookie = net.request("<REMOVED>", {
		method = "GET",
		headers = { ["x-api-key"] = auth.get_iac_key() },
	})

	assert(cookie.ok)

	return cookie.body
end

-- pulls the roblox cookie from auth
function auth.get_roblox_cookie(): string
	if security_cookie ~= false then
		return security_cookie
	else
		security_cookie = auth.pull_security_cookie()
		assert(security_cookie, "luau")
		return security_cookie
	end
end

function auth.update_roblox_cookie(new_cookie: string)
	security_cookie = new_cookie

	const response = net.request("<REMOVED>", {
		method = "POST",
		body = new_cookie,
		headers = { ["x-api-key"] = auth.get_iac_key(), ["Content-Type"] = "text/plain" },
	})

	if response.ok == false then
		print(styles.error(styles.header(`unable to update roblox cookie. not fatal, but manual intervention is required`)))
		print(styles.error(`{response.status} {response.body}`))
	else
		print(styles.success(`{response.ok} updated roblox cookie!`))
	end
end

function auth.pull_csrf_token()
	const response = net.request("https://auth.roblox.com/v2/logout", {
		method = "POST",
		headers = { ["Cookie"] = `.ROBLOSECURITY={auth.get_roblox_cookie()}` },
	})

	-- if response.headers["Set-Cookie"] then
	-- 	auth.update_roblox_cookie(response.headers["Set-Cookie"])
	-- end

	csrf_token = response.headers["x-csrf-token"]
	assert(csrf_token, `missing token`)
	return csrf_token
end

function auth.get_csrf_token(): string
	if csrf_token == false then
		auth.pull_csrf_token()
	end

	assert(csrf_token, "luau")
	return csrf_token
end

return auth
