const formdata = require("../formdata")
const fs = require("@std/fs")
const hash_icon = require("../hash_icon")
const json = require("@vendor/json")
const net = require("@std/net")
const path = require("@std/path")
const request = require("../request")
const styles = require("../../styles")
const types = require("../types")
local universe = require("./universe")

local gamepass = {}

const function get_form(gamepass: types.Gamepass)
	const form = formdata.new()

	form:append("name", gamepass.name)
	form:append("description", gamepass.description)

	form:append("imageFile", fs.readFileToString(gamepass.icon), `icon{path.extname(gamepass.icon)}`)
	form:append("isForSale", `{gamepass.robux_price ~= nil}`)
	if gamepass.robux_price then
		form:append("price", `{gamepass.robux_price}`)
		form:append("isManagedPricingEnabled", `{gamepass.managed_pricing or false}`)
	end

	return form
end

-- needs game-pass:write
function gamepass.create(
	universe_id: number,
	gamepass_data: types.Gamepass,
	retry_managed_pricing: boolean?
): { ok: true, gamepass_id: number } | { ok: false, response: net.Response }
	print(styles.detail(`creating new gamepass under {universe_id} (name={gamepass_data.name})`))
	const form = get_form(gamepass_data)
	const response = request.request(
		"POST",
		`https://apis.roblox.com/game-passes/v1/universes/{universe_id}/game-passes`,
		form:getBody(),
		{ ["Content-Type"] = form:getHeader() }
	)

	if response.ok then
		const gamepass_id = json.deserialize(response.body).gamePassId
		print(styles.success(`created gamepass id={gamepass_id}`))
		return { ok = true, gamepass_id = gamepass_id }
	else
		if response.body:find("Managed pricing must be accepted") and not retry_managed_pricing then
			universe.accept_managed_pricing(universe_id)
			return gamepass.create(universe_id, gamepass_data, true)
		end

		print(styles.warning(styles.header(`failed to create gamepass {gamepass_data.name} on universe {universe_id}`)))
		print(styles.warning(`{response.status} {response.body}`))
		return { ok = false, response = response }
	end
end

function gamepass.update_id(
	universe_id: number,
	gamepass_id: number,
	gamepass_data: types.Gamepass,
	retry_dynamic_pricing: boolean?
)
	print(styles.detail(`updating gamepass under {universe_id} with id {gamepass_id} (name={gamepass_data.name})`))
	const form = get_form(gamepass_data)
	const response = request.request(
		"PATCH",
		`https://apis.roblox.com/game-passes/v1/universes/{universe_id}/game-passes/{gamepass_id}`,
		form:getBody(),
		{ ["Content-Type"] = form:getHeader() }
	)

	if response.ok then
		print(styles.success(`successfully updated gamepass`))
		return { ok = true }
	else
		if response.body:find("Managed pricing must be accepted") and not retry_dynamic_pricing then
			universe.accept_managed_pricing(universe_id)
			return gamepass.update_id(universe_id, gamepass_id, gamepass_data, true)
		end

		print(
			styles.warning(
				styles.header(`failed to patch gamepass {gamepass_data.name} ({gamepass_id}) on universe {universe_id}`)
			)
		)
		print(styles.warning(`{response.status} {response.body}`))
		return { ok = false, response = response }
	end
end

function gamepass.has_changed(old: types.Gamepass, new: types.Gamepass, old_hash: string): boolean
	const hash = hash_icon.hash(new.icon)

	const change_settings = new.name ~= old.name
		or new.description ~= old.description
		or new.managed_pricing ~= old.managed_pricing
		or new.robux_price ~= old.robux_price
	const change_icon = hash ~= old_hash

	return change_settings or change_icon
end

return gamepass
