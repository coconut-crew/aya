const json = require("@vendor/json")
const net = require("@std/net")
const request = require("../request")
const styles = require("../../styles")
const types = require("../types")

const places = {}

const BASEPLATE = 95206881

function places.create_place(universe_id: number): { ok: true, place_id: number } | { ok: false, response: net.Response }
	-- const actual_universe_id = universe.get_actual_universe_id(universe_id) or universe_id
	-- if actual_universe_id then
	-- 	print(styles.success(`got universe id {actual_universe_id}`))
	-- else
	-- 	print(styles.warning(`missing actual universe id`))
	-- end

	print(styles.detail(`creating place under {universe_id}`))
	const response = request.request(
		"POST",
		`https://apis.roblox.com/universes/v1/user/universes/{universe_id}/places`,
		json.serialize({ templatePlaceId = BASEPLATE }),
		{ ["Content-Type"] = "application/json" },
		{},
		true
	)

	if response.ok == false then
		print(styles.error(`failed to create place under {universe_id}`))
		print(styles.error(`{response.status} {response.body}`))
		print(styles.detail("url"))

		print(styles.detail("body"))
		print(styles.detail(`https://apis.roblox.com/universes/v1/user/universes/{universe_id}/places`))
		print(styles.detail(json.serialize(response.headers, true)))
		print(styles.detail(json.serialize({ templatePlaceId = BASEPLATE }, true)))
		return {
			ok = false,
			response = response,
		}
	else
		const place_id = json.deserialize(response.body).placeId
		print(styles.success(`created place under {universe_id} with id {place_id}`))
		return {
			ok = true,
			place_id = place_id,
		}
	end
end

function places.publish_place_file(universe_id: number, place_id: number, place_file: string)
	print(styles.detail(`publishing place file for universe: {universe_id} - place: {place_id}`))
	const response = request.request(
		"POST",
		`https://apis.roblox.com/universes/v1/{universe_id}/places/{place_id}/versions`,
		place_file,
		{ ["Content-Type"] = "application/octet-stream" },
		{ versionType = "Published" }
	)

	if response.ok then
		print(styles.success(`successfully published place file`))
	else
		print(styles.error(`failed to publish place: {response.status} {response.body}`))
	end

	return response
end

function places.update_place_settings(place_id: number, settings: types.Place)
	print(styles.detail(`updating place settings for {place_id}`))
	const response = request.request(
		"PATCH",
		`https://develop.roblox.com/v2/places/{place_id}`,
		json.serialize({
			name = settings.name,
			description = settings.description,

			maxPlayerCount = settings.max_player_count,
			socialSlotType = if settings.server_fill == "roblox_optimized"
				then "Automatic"
				elseif settings.server_fill == "maximum" then "Empty"
				else "Custom",
			customSocialSlotsCount = if type(settings.server_fill) == "table" then settings.server_fill.reversed_slots else nil,

			allowCopying = settings.allow_copying or false,
			allowedGearTypes = {},
			isAllGenresAllowed = false,
		}),
		{ ["Content-Type"] = "application/json" },
		nil,
		true
	)

	if response.ok == false then
		print(styles.error(`failed to update place data`))
		print(styles.error(`{response.status} {response.body}`))
	else
		print(styles.success(`successfully updated place data`))
	end

	return response
end

function places.get_root_place(experience: types.Experience): (types.Place, string)
	local starter_place = nil
	local starter_place_key = nil

	for key, place in experience.places do
		if place.root then
			if starter_place then
				error(`duplicate starter place named {key}`)
			end

			starter_place_key, starter_place = key, place
		end
	end

	if starter_place == nil or starter_place_key == nil then
		error(`missing starter place`)
	end

	return starter_place, starter_place_key
end

function places.has_changed(old: types.Place, new: types.Place)
	const has_changed = new.name ~= old.name
		or new.description ~= old.description
		or new.max_player_count ~= old.max_player_count
		or new.server_fill ~= old.server_fill
		or new.allow_copying ~= old.allow_copying

	return has_changed
end

return places
