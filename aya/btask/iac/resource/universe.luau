const json = require("@vendor/json")
const net = require("@std/net")
const request = require("../request")
const styles = require("../../styles")
const types = require("../types")

const universe = {}

function universe.create(
	owner: types.Owner
): { ok: true, universe_id: number, root_place_id: number } | { ok: false, response: net.Response }
	print(styles.detail(`attempting to create a new universe under {owner.kind} id={owner.id}`))
	const response = request.request(
		"POST",
		"https://apis.roblox.com/universes/v1/universes/create",
		json.serialize({ templatePlaceId = 95206881 }),
		{ ["Content-Type"] = "application/json" },
		if owner.kind == "community" then { groupId = owner.id } else { userId = owner.id },
		true
	)

	if response.ok then
		const body = json.deserialize(response.body)
		print(styles.success(`created new universe id={body.universeId} root place={body.rootPlaceId}`))

		return { ok = true, universe_id = body.universeId, root_place_id = body.rootPlaceId }
	else
		print(styles.warning(styles.header(`failed to create universe under {owner.id} (kind={owner.kind})`)))
		print(styles.warning(`{response.status} {response.body}`))
		return { ok = false, response = response }
	end
end

function universe.get_actual_universe_id(asset_universe_id: number)
	print(styles.detail(`getting actual universe id for {asset_universe_id}`))
	const universe_id_res =
		request.request("GET", `https://apis.roblox.com/universes/v1/places/{asset_universe_id}/universe`, "", {})

	if universe_id_res.ok == false then
		print(styles.error(`failed to retrieve id`))
		print(styles.error(`{universe_id_res.status} {universe_id_res.body}`))
		return nil
	else
		const id = json.deserialize(universe_id_res.body).universeId
		print(styles.success(`actual universe id is {id}`))
		print(universe_id_res.body)
		return id
	end
end

function universe.accept_managed_pricing(universe_id: number)
	print(styles.detail(`attempting to accept managed pricing for {universe_id}`))
	const response = request.request(
		"POST",
		`https://apis.roblox.com/price-configuration-api/v1/universes/{universe_id}/managed-pricing:accept`,
		"",
		{},
		nil,
		true
	)

	if response.ok then
		print(styles.success(`managed pricing has been accepted`))
		return { ok = true }
	else
		print(styles.error(`managed pricing has not been accepted`))
		print(styles.error(`{response.status} {response.body}`))
		return { ok = false, response = response }
	end
end

return universe
