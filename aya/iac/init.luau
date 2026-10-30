const badges = require("@self/resource/badges")
const db = require("@self/db")
const developerproduct = require("@self/resource/developerproduct")
const gamepass = require("@self/resource/gamepass")
const hash_icon = require("@self/hash_icon")
const places = require("@self/resource/places")
const styles = require("./styles")
const types = require("@self/types")
const universe = require("@self/resource/universe")
const universe_settings = require("@self/resource/universe_settings")

export type ExperienceConfig = types.Experience
export type ExperienceLockFile = types.ExperienceResult

--[[

iac allows for infrastructure as code. this supports defining a limited subset of the game as a luau file

iac.create_new_experience(experience): ExperienceResult
iac.update_experience(experience, old_experience_result): ExperienceResult

]]

local iac = {}

function iac.create_new_experience<T>(experience: T & types.Experience): types.ExperienceResult
	const universe = universe.create(experience.owner)

	if universe.ok == false then
		error("failed to create universe")
	end

	const universe_id = universe.universe_id
	const root_place_id = universe.root_place_id

	if universe_settings.update_settings(universe_id, experience).ok == false then
		error("exit")
	end

	const stored_gamepasses = {}
	const stored_badges = {}
	const stored_developerproducts = {}
	const stored_places = {}

	const stored_gamepass_icons = {}
	const stored_badge_icons = {}
	const stored_product_icons = {}

	for key, place in experience.places do
		local place_id = if place.root then root_place_id else nil

		if place_id == nil then
			const response = places.create_place(universe_id)
			if response.ok then
				place_id = response.place_id
			else
				error("exit")
			end
		else
			print("root place determined, avoiding creating new place")
		end

		assert(place_id, "luau")

		if places.update_place_settings(place_id, place).ok == false then
			error("exit")
		end

		stored_places[key] = place_id
	end

	if experience.gamepasses ~= nil then
		for key, gamepass_data in experience.gamepasses do
			const response = gamepass.create(universe_id, gamepass_data)

			if response.ok then
				stored_gamepasses[key] = response.gamepass_id
				stored_gamepass_icons[tostring(response.gamepass_id)] = hash_icon.hash(gamepass_data.icon)
			else
				print(styles.error(`failed to make gamepass because {response.response.body}`))
			end
		end
	end

	if experience.products ~= nil then
		for key, product_data in experience.products do
			const response = developerproduct.create(universe_id, product_data)

			if response.ok then
				stored_developerproducts[key] = response.product_id
				stored_product_icons[tostring(response.product_id)] = hash_icon.hash(product_data.icon)
			else
				print(styles.error(`failed to make product because {response.response.body}`))
			end
		end
	end

	if experience.badges ~= nil then
		for key, badge_data in experience.badges do
			const response = badges.create(universe_id, badge_data)

			if response.ok then
				stored_badges[key] = response.badge_id
				stored_badge_icons[tostring(response.badge_id)] = hash_icon.hash(badge_data.icon)
			else
				print(styles.error(`failed to make badge because {response.response.body}`))
			end
		end
	end

	const result = {
		template = experience :: types.Experience,

		universe_id = universe_id,
		root_place_id = root_place_id,

		place_ids = stored_places,
		products = stored_developerproducts,
		gamepasses = stored_gamepasses,
		badges = stored_badges,

		product_icons = stored_product_icons,
		gamepass_icons = stored_gamepass_icons,
		badge_icons = stored_badge_icons,
	}

	return result :: any
end

function iac.update_experience<T>(
	experience: types.Experience,
	old_experience_data: types.ExperienceResult?
): (types.ExperienceResult, boolean)
	if old_experience_data == nil or old_experience_data.universe_id == nil then
		return iac.create_new_experience(experience), true
	end

	assert(old_experience_data.template)

	const old: types.Experience = old_experience_data.template
	const new: types.Experience = experience
	const universe_id = old_experience_data.universe_id

	local succeeded = false

	const new_template_data = table.clone(old_experience_data)
	new_template_data.badge_icons = table.clone(old_experience_data.badge_icons)
	new_template_data.product_icons = table.clone(old_experience_data.product_icons)
	new_template_data.gamepass_icons = table.clone(old_experience_data.gamepass_icons)

	new_template_data.badges = table.clone(old_experience_data.badges)
	new_template_data.gamepasses = table.clone(old_experience_data.gamepasses)
	new_template_data.place_ids = table.clone(old_experience_data.place_ids)
	new_template_data.products = table.clone(old_experience_data.products)
	new_template_data.template = experience

	if universe_settings.has_changed(old, new) then
		universe_settings.update_settings(old_experience_data.universe_id, experience)
	end

	const root_place_old, old_rootkey = places.get_root_place(old)
	const root_place_new, new_rootkey = places.get_root_place(new)

	if places.has_changed(root_place_old, root_place_new) then
		places.update_place_settings(old_experience_data.root_place_id, root_place_new)
	end

	new_template_data.place_ids[old_rootkey] = old_experience_data.place_ids[new_rootkey]
	new_template_data.place_ids[new_rootkey] = new_template_data.root_place_id

	-- we need to fill the remaining places out
	const previous_place_id_for_new = old_experience_data.place_ids[new_rootkey :: any] -- the place that occupied this id is no longer the starter place
	const swapped_place_id = old_rootkey ~= new_rootkey

	for place_key, new_place in new.places do
		-- we skip when we determine that the current key we're processing was the starter place
		if place_key == new_rootkey then
			continue
		end

		const old_place = old.places[place_key]
		const old_place_id = if place_key == old_rootkey and swapped_place_id
			then previous_place_id_for_new
			else old_experience_data.place_ids[place_key :: any]

		if old_place_id == nil then
			-- we need to create a new place
			const response = places.create_place(universe_id)

			if response.ok == false then
				print(styles.error(`unable to create a new place id`))
				succeeded = false
				continue
			end

			places.update_place_settings(response.place_id, new_place)
			new_template_data.place_ids[place_key] = response.place_id
		elseif places.has_changed(old_place, new_place) then
			places.update_place_settings(old_place_id, new_place)
		end
	end

	if new.gamepasses then
		for gamepass_key, new_gamepass in new.gamepasses do
			const old_gamepass_id = old_experience_data.gamepasses[gamepass_key :: any]
			const old_gamepass = old.gamepasses and old.gamepasses[gamepass_key]

			if old_gamepass_id == nil or old_gamepass == nil then
				const response = gamepass.create(universe_id, new_gamepass)

				if response.ok == false then
					print(styles.error(`unable to create a new gamepass`))
					succeeded = false
					continue
				end

				new_template_data.gamepasses[gamepass_key :: any] = response.gamepass_id
				new_template_data.gamepass_icons[tostring(response.gamepass_id)] = hash_icon.hash(new_gamepass.icon)
			elseif
				gamepass.has_changed(old_gamepass, new_gamepass, old_experience_data.gamepass_icons[tostring(old_gamepass_id)])
			then
				const response = gamepass.update_id(universe_id, old_gamepass_id, new_gamepass)

				if response.ok == false then
					print(styles.error("unable to update a gamepass"))
					succeeded = false
					continue
				end
				new_template_data.gamepass_icons[tostring(old_gamepass_id)] = hash_icon.hash(new_gamepass.icon)
			end
		end
	end

	if new.products then
		for product_key, new_product in new.products do
			const old_product_id = old_experience_data.products[product_key :: any]
			const old_product = old.products and old.products[product_key]

			if old_product_id == nil or old_product == nil then
				const response = developerproduct.create(universe_id, new_product)

				if response.ok == false then
					print(styles.error(`unable to create a new product`))
					succeeded = false
					continue
				end

				new_template_data.products[product_key :: any] = response.product_id
				new_template_data.product_icons[tostring(response.product_id)] = hash_icon.hash(new_product.icon)
			elseif
				developerproduct.has_changed(
					old_product,
					new_product,
					old_experience_data.product_icons[tostring(old_product_id)]
				)
			then
				const response = developerproduct.update_id(universe_id, old_product_id, new_product)

				if response.ok == false then
					print(styles.error("unable to update a product"))
					succeeded = false
					continue
				end

				new_template_data.product_icons[tostring(old_product_id)] = hash_icon.hash(new_product.icon)
			end
		end
	end

	if new.badges then
		for badge_key, new_badge in new.badges do
			const old_badge_id = old_experience_data.badges[badge_key :: any]
			const old_badge = old.badges and old.badges[badge_key]

			if old_badge_id == nil or old_badge == nil then
				const response = badges.create(universe_id, new_badge)

				if response.ok == false then
					print(styles.error(`unable to create a new badge`))
					succeeded = false
					continue
				end

				new_template_data.badges[badge_key :: any] = response.badge_id
				new_template_data.badge_icons[tostring(response.badge_id)] = hash_icon.hash(new_badge.icon)
			else
				const changed =
					badges.has_changed(old_badge, new_badge, old_experience_data.product_icons[tostring(old_badge_id)])

				if changed.change_icon then
					const response = badges.update_icon(old_badge_id, new_badge)
					if response.ok == false then
						print(styles.error("unable to update a badge"))
						succeeded = false
						continue
					end

					new_template_data.badge_icons[tostring(old_badge_id)] = hash_icon.hash(new_badge.icon)
				end

				if changed.change_settings then
					const response = badges.update_id(old_badge_id, new_badge)
					if response.ok == false then
						print(styles.error("unable to update a badge"))
						succeeded = false
						continue
					end
				end
			end
		end
	end

	return new_template_data, succeeded
end

function iac.get_result(key: string): types.ExperienceResult?
	return db.get_result(key)
end

function iac.get_unused(): types.ExperienceResult?
	const results = db.obtain_unused_experience_id()

	if results then
		return results.result
	end

	return nil
end

function iac.update_result(key: string, result: types.ExperienceResult)
	return db.use_experience_id(key, result)
end

function iac.remove_key(key: string)
	return db.unuse_id(key)
end

function iac.publish_to_target(result: types.ExperienceResult, place_key: string, place_file: string)
	const universe_id = result.universe_id
	const place_id = result.place_ids[place_key]

	if universe_id == nil or place_id == nil then
		print(styles.error(`missing universe id {universe_id} or place id {place_id}. cannot publish`))
		return
	end

	places.publish_place_file(universe_id, place_id, place_file)
end

-- not implementing this atm sorry
-- -- attempts to reconstruct the experience result from a given experience id.
-- -- the result will be printed to output. it is recommended to modify yourself
-- function iac.obtain_result_from_experience(experience_id: number): types.ExperienceResult

-- end

return iac
