const avataraccessoryrules = require("../avataraccessoryrules")
const json = require("@vendor/json")
const request = require("../request")
const styles = require("../../styles")
const types = require("../types")

const universe = {}

const to_engine_avatar_settings = avataraccessoryrules.to_engine_avatar_settings

const function deep_equals(a: any, b: any): boolean
	if typeof(a) ~= typeof(b) then
		return false
	end

	if typeof(a) == "number" then
		-- Floating point error!
		return math.abs(a - b) < 0.0001
	end

	if typeof(a) == "table" then
		local visitedKeys = {}

		for key, value in a do
			visitedKeys[key] = true

			local success = deep_equals(value, b[key])
			if not success then
				return false
			end
		end

		for key, value in b do
			if not visitedKeys[key] then
				local success = deep_equals(value, a[key])

				if not success then
					return false
				end
			end
		end

		return true
	end

	if a == b then
		return true
	end

	return false
end

const function get_root_place(experience: types.Experience)
	local starter_place = nil

	for key, place in experience.places do
		if place.root then
			if starter_place then
				error(`duplicate starter place named {key}`)
			end

			starter_place = place
		end
	end

	if starter_place == nil then
		error(`missing starter place`)
	end

	return starter_place
end

const function get_social_link(
	--stylua: ignore
	links: { types.SocialLink },
	matches: string
): types.SocialLink?
	for _, link in links do
		if string.match(link.uri, matches) then
			return link
		end
	end

	return nil
end

type UniverseSettings = {
	path: string,
	createTime: string,
	updateTime: string,
	displayName: string,
	description: string,
	user: string,
	group: string,
	visibility: string,
	facebookSocialLink: types.SocialLink?,
	twitterSocialLink: types.SocialLink?,
	youtubeSocialLink: types.SocialLink?,
	twitchSocialLink: types.SocialLink?,
	discordSocialLink: types.SocialLink?,
	robloxGroupSocialLink: types.SocialLink?,
	voiceChatEnabled: boolean,
	ageRating: string,
	privateServerPriceRobux: number,
	desktopEnabled: boolean,
	mobileEnabled: boolean,
	tabletEnabled: boolean,
	consoleEnabled: boolean,
	vrEnabled: boolean,
	rootPlace: string,
}

-- requires api key to have universe:write
-- function universe.update_experience_settings(
-- 	universe_id: number,
-- 	experience: types.Experience
-- ): { ok: true, latest: UniverseSettings, response: net.Response } | { ok: false, response: net.Response }
-- 	const response = request.request(
-- 		"PATCH",
-- 		`https://apis.roblox.com/cloud/v2/universes/{universe_id}`,
-- 		json.serialize({
-- 			voiceChatEnabled = experience.spatial_voice and experience.spatial_voice.enabled or false,
-- 			privateServerPriceRobux = if experience.private_servers == true
-- 				then 0
-- 				elseif experience.private_servers then experience.private_servers.robux
-- 				else nil,

-- 			consoleEnabled = experience.playable_device["console"] == true,
-- 			desktopEnabled = experience.playable_device["pc"] == true,
-- 			mobileEnabled = experience.playable_device["mobile"] == true,
-- 			tabletEnabled = experience.playable_device["tablet"] == true,
-- 			vrEnabled = experience.playable_device["vr"] == true,

-- 			group = if experience.owner.kind == "community" then experience.owner.id else nil,
-- 			user = if experience.owner.kind == "user" then experience.owner.id else nil,

-- 			facebookSocialLink = get_social_link(experience.social_links or {}, "facebook.com"),
-- 			twitterSocialLink = get_social_link(experience.social_links or {}, "x.com"),
-- 			youtubeSocialLink = get_social_link(experience.social_links or {}, "youtube.com"),
-- 			twitchSocialLink = get_social_link(experience.social_links or {}, "twitch.tv"),
-- 			discordSocialLink = get_social_link(experience.social_links or {}, "discord.gg"),
-- 			robloxGroupSocialLink = get_social_link(experience.social_links or {}, "roblox.com"),
-- 		}),
-- 		{ ["Content-Type"] = "application/json" },
-- 		{}
-- 	)

-- 	if response.ok then
-- 		const body = json.deserialize(response.body)

-- 		return { ok = true, latest = body, response = response }
-- 	else
-- 		return { ok = false, response = response }
-- 	end
-- end

const function to_playable_devices(experience: types.Experience): { string }
	const playable_devices = {}

	assert(experience.playable_device)

	for device in experience.playable_device do
		const mapped = if device == "console"
			then "Console"
			elseif device == "desktop" then "Compuiter"
			elseif device == "mobile" then "Mobile"
			elseif device == "tablet" then "Tablet"
			elseif device == "vr" then "vr"
			else error(`unable to map device {device}`)

		table.insert(playable_devices, mapped)
	end

	return playable_devices
end

const function to_range(range: types.Range?): { number }
	return if range then { range.min, range.max } else { 0, 1 }
end

function universe.update_settings(universe_id: number, experience: types.Experience)
	print(styles.detail(`will be updating the universe settings for {universe_id}`))

	local made_public = false
	if experience.public ~= nil then
		const activate_or_deactivate = if experience.public then "activate" else "deactivate"
		const response = request.request(
			"POST",
			`https://apis.roblox.com/legacy-develop/v1/universes/{universe_id}/{activate_or_deactivate}`,
			"",
			{},
			nil
		)

		if response.ok == false then
			print(styles.error(`failed to {activate_or_deactivate} universe`))
			print(styles.error(`{response.status} {response.body}`))
		else
			print(styles.success(`successfully {activate_or_deactivate}d universe`))
		end
		made_public = response.ok
	end

	const is_public = experience.public and made_public
	const body = json.serialize({
		name = experience.name,
		description = experience.description,
		-- allowPrivateServers = false,
		allowPrivateServers = if is_public then experience.private_servers ~= nil else nil,
		privateServerPrice = if is_public and experience.private_servers == true
			then 0
			elseif experience.public and experience.private_servers then experience.private_servers.robux
			else nil,

		isArchived = false,
		isFriendsOnly = false,

		genre = experience.genre,

		playableDevices = to_playable_devices(experience),
		engineAvatarSettings = json.serialize(to_engine_avatar_settings(experience)),

		isForSale = if experience.paid_access then true else false,
		price = if experience.paid_access then experience.paid_access.robux else nil,

		studioAccessToApisAllowed = experience.enable_studio_access_to_apis,
		permissions = {
			IsThirdPartyTeleportAllowed = experience.allow_third_party_teleports or false,
			IsThirdPartyAssetAllowed = true,
			IsThirdPartyPurchaseAllowed = experience.allow_third_party_sales or false,
			IsClientTeleportAllowed = false,
		},
	})
	const response = request.request(
		"PATCH",
		`https://develop.roblox.com/v2/universes/{universe_id}/configuration`,
		body,
		{ ["Content-Type"] = "application/json" },
		nil,
		true
	)

	if response.ok == false then
		print(styles.error(`failed to update universe settings`))
		print(styles.error(`{response.status} {response.body}`))
		print(styles.detail(`request body`))
		print(json.serialize(json.deserialize(body), true))
	else
		print(styles.success(`updated universe settings for {universe_id}`))
	end

	return response
end

function universe.has_changed(old: types.Experience, new: types.Experience)
	const changed = not deep_equals(old.private_servers, new.private_servers)
		or old.genre ~= new.genre
		or not deep_equals(old.playable_device, new.playable_device)
		or not deep_equals(to_engine_avatar_settings(old), to_engine_avatar_settings(new))
		or not deep_equals(old.paid_access, new.paid_access)
		or old.enable_studio_access_to_apis ~= new.enable_studio_access_to_apis
		or old.allow_third_party_teleports ~= new.allow_third_party_teleports
		or new.allow_third_party_sales ~= new.allow_third_party_sales
		or new.description ~= old.description
		or new.name ~= old.name

	return changed
end

return universe
