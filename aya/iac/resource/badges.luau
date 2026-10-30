const formdata = require("../formdata")
const fs = require("@std/fs")
const hash_icon = require("../hash_icon")
const json = require("@vendor/json")
const net = require("@std/net")
const path = require("@std/path")
const request = require("../request")
const styles = require("../../styles")
const types = require("../types")

local badges = {}

const function get_form(badge: types.Badge)
	const form = formdata.new()

	form:append("name", badge.name)
	form:append("description", badge.description)
	form:append("paymentSourceType", `{2}`)

	const extension = path.extname(badge.icon)
	const icon_format = if extension == "jpg"
		then "image/jpg"
		elseif extension == "jpeg" then "image/jpeg"
		elseif extension == "png" then "image/png"
		elseif extension == "webp" then "image/webp"
		elseif extension == "gif" then "image/gif"
		else "text/plain"

	form:append("files", fs.readFileToString(badge.icon), nil, icon_format)
	form:append("expectedCost", "0")
	form:append("isActive", `{badge.enabled or false}`)

	return form
end

-- needs legacy-universe.badge:manage-and-spend-robux
function badges.create(
	universe_id: number,
	badge: types.Badge
): { ok: true, badge_id: number } | { ok: false, response: net.Response }
	print(styles.detail(`creating new badge under {universe_id} for {badge.name}`))
	const form = get_form(badge)
	const response = request.request(
		"POST",
		`https://apis.roblox.com/legacy-badges/v1/universes/{universe_id}/badges`,
		form:getBody(),
		{ ["Content-Type"] = form:getHeader() }
	)

	if response.ok then
		const badge_id = json.serialize(response.body).id
		print(styles.success(`successfully created new badge with id {badge_id}`))
		return { ok = true, badge_id = badge_id }
	else
		print(styles.warning(styles.header(`failed to create badge {badge.name} on universe {universe_id}`)))
		print(styles.warning(`{response.status} {response.body}`))
		return { ok = false, response = response }
	end
end

-- legacy-badge:manage
function badges.update_icon(badge_id: number, badge: types.Badge): { ok: true } | { ok: false, response: net.Response }
	print(styles.detail(`updating badge icon {badge_id} with name {badge.name}`))
	const form = formdata.new()

	const extension = path.extname(badge.icon)
	const icon_format = if extension == "jpg"
		then "image/jpg"
		elseif extension == "jpeg" then "image/jpeg"
		elseif extension == "png" then "image/png"
		elseif extension == "webp" then "image/webp"
		elseif extension == "gif" then "image/gif"
		else "text/plain"

	form:append("files", fs.readFileToString(badge.icon), nil, icon_format)

	const response = request.request(
		"POST",
		`https://apis.roblox.com/legacy-publish/v1/badges/{badge_id}/icon`,
		form:getBody(),
		{ ["Content-Type"] = form:getHeader() }
	)

	if response.ok then
		print(styles.success(`successfully updated badge icon`))
		return { ok = true }
	else
		print(styles.warning(styles.header(`failed to patch badge icon {badge.name} ({badge_id})`)))
		print(styles.warning(`{response.status} {response.body}`))
		return { ok = false, response = response }
	end
end

--legacy-universe.badge:write
function badges.update_id(badge_id: number, badge: types.Badge): { ok: true } | { ok: false, response: net.Response }
	print(styles.detail(`updating badge settings for {badge_id} for {badge.name}`))
	const response = request.request(
		"POST",
		`https://apis.roblox.com/legacy-badges/v1/badges/{badge_id}`,
		json.serialize({
			name = badge.name,
			description = badge.description,
			enabled = badge.enabled,
		}),
		{ ["Content-Type"] = "application/json" }
	)

	if response.ok then
		print(styles.success(`successfully updated badge`))
		return { ok = true }
	else
		print(styles.warning(styles.header(`failed to patch badge {badge.name} ({badge_id})`)))
		print(styles.warning(`{response.status} {response.body}`))
		return { ok = false, response = response }
	end
end

function badges.has_changed(
	old: types.Badge,
	new: types.Badge,
	old_hash: string
): { change_icon: boolean, change_settings: boolean }
	const hash = hash_icon.hash(new.icon)

	const change_settings = new.name ~= old.name or new.description ~= old.description or new.enabled ~= old.enabled
	const change_icon = hash ~= old_hash

	return {
		change_settings = change_settings,
		change_icon = change_icon,
	}
end

return badges
