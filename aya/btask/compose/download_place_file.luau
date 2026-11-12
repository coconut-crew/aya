local fs = require("@std/fs")
local json = require("@agnostic/utils/json")
local net = require("@std/net")
local project_decl = require("../../project_decl")
local pull_latest_version = require("./pull-latest-version")
local styles = require("../styles")
local zzlib = require("../../vendor/zzlib")

type RobloxPlace = {
	universe_id: number,
	place_id: number,

	version: string?,
}

const function is_cached(place: RobloxPlace)
	return fs.exists(`.cache/{place.place_id}/rbxl/{place.version}.rbxl`)
end

const function load_cached(place: RobloxPlace): string
	local ok, file = pcall(fs.readFileToString, `.cache/{place.place_id}/rbxl/{place.version}.rbxl`)

	if not ok then
		ok, file = pcall(fs.readFileToString, `.cache/{place.place_id}/rbxl/latest.rbxl`)
	end

	if not ok then
		error(styles.error(`unable to load a fallback version for {place.place_id}.`))
	end

	return file
end

const function download(place: RobloxPlace, version: number): (string, string)
	local api_key = string.gsub(fs.readFileToString("./secrets/place_download"), "%s+$", "")

	fs.createDirectory(`.cache/{place.place_id}/rbxl`, { makeParents = true })

	local version = place_version_lock.get_version(place)

	if version == nil then
		print(styles.error(`Unable to find a version for universe {place.universe_id}, place {place.place_id}`))
		print(styles.warning(`Getting latest version from Roblox and adding to lock file`))

		local ok, place_version = pull_latest_version.pull(place.place_id)
		version = place_version

		if ok then
			place_version_lock.update_version_immediate(place, version)
		else
			print(
				styles.warning(
					`Getting latest version from Roblox failed. Not writing version for {place.place_id} to lock file`
				)
			)
		end
	end

	assert(version, "missing version?")
	print(styles.header(`getting version {version} of {place.place_id}`))

	-- https://apis.roblox.com/universes/v1/{universeId}/places/{placeId}/versions download
	-- https://apis.roblox.com/asset-delivery-api/v1/assetId/{assetId}/version/{versionNumber} download for version

	local rbxlbody: string

	if is_cached(place, version) then
		print(styles.header(`loading version {version} of {place.place_id} from cache`))
		rbxlbody = load_cached(place, version)
	else
		print(styles.header(`downloading version {version} of {place.place_id}`))
		local response =
			net.request(`https://apis.roblox.com/asset-delivery-api/v1/assetId/{place.place_id}/version/{version}`, {
				headers = {
					["x-api-key"] = api_key,
				},
			})
		local body: { location: string } = json.deserialize(response.body) :: any

		local location = body.location

		local cdn_response = net.request(location, {
			method = "GET",
			headers = {
				["x-api-key"] = api_key,
			},
		})

		rbxlbody = cdn_response.body

		if not cdn_response.ok then
			print(
				styles.error(
					`Failed to download version {version} for {place.universe_id}:{place.place_id}. Attempting fallback`
				)
			)
			print(styles.error(`{response.status}: {response.body}`))

			-- is_zipped = true
			rbxlbody = load_cached(place, version)
		else
			if true then
				local ok, new_body = pcall(zzlib.gunzip, rbxlbody)
				if not ok then
					print(styles.error(new_body))
					-- error(if #rbxlbody < 2000 then rbxlbody else "")
				else
					rbxlbody = new_body
				end
			end
			fs.writeStringToFile(`.cache/{place.place_id}/rbxl/{version}.rbxl`, rbxlbody)
		end
	end

	fs.writeStringToFile(`.cache/{place.place_id}/rbxl/latest.rbxl`, rbxlbody)

	return rbxlbody, `.cache/{place.place_id}/rbxl/latest.rbxl`
end
