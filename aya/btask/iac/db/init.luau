const auth = require("./auth")
const json = require("@vendor/json")
const net = require("@std/net")
const styles = require("../styles")
const template = require("@self/template")
const types = require("./types")
const db = {}

function db.migrate(input)
	if input.version == nil then
		const template = {
			version = 0,
			unused_experiences = {} :: { number },
			map_key_experience = {} :: { [string]: number },
			experience_results = {} :: { [string]: types.ExperienceResult },
		}

		for key: string, result: types.ExperienceResult in input do
			if result.universe_id == nil then
				continue
			end

			template.map_key_experience[key] = result.universe_id
			template.experience_results[tostring(result.universe_id)] = result
		end

		return db.migrate(template)
	end

	return input
end

function db.get_results(): template.Template
	const response = net.request("<REMOVED>", {
		method = "GET",
		headers = {
			["x-api-key"] = auth.get_iac_key(),
			["Content-Type"] = "application/json",
			["User-Agent"] = "lute iac tool",
		},
	})

	if response.ok == false then
		error(`{response.status} {response.body}`)
	end

	if response.body == "" then
		return template()
	end

	return db.migrate(json.deserialize(response.body)) :: any
end

function db.get_result(key: string): types.ExperienceResult?
	const results = db.get_results()
	const experience_id = results.map_key_experience[key]

	if experience_id then
		return results.experience_results[tostring(experience_id)]
	end

	return nil
end

function db.set_results(results: template.Template)
	const response = net.request("<REMOVED>", {
		method = "POST",
		body = json.serialize(results :: any),
		headers = {
			["x-api-key"] = auth.get_iac_key(),
			["Content-Type"] = "application/json",
			["User-Agent"] = "lute iac tool",
		},
	})

	if response.ok == false then
		print(styles.error(`updating experience results in this js db failed`))
		print(styles.error(`{response.status} {response.body}`))
		print(styles.detail("body"))
		print(styles.detail(json.serialize(results :: any, true)))
	else
		print(styles.success(`updated results {response.body}`))
	end

	return response
end

function db.obtain_unused_experience_id(): types.ExperienceResult?
	const results = db.get_results()

	if #results.unused_experiences == 0 then
		return nil
	end

	const experience_id = table.remove(results.unused_experiences)
	assert(experience_id, "missing experience id, should be there.")
	const experience_data = results.experience_results[tostring(experience_id)]

	return experience_data
end

function db.use_experience_id(key: string, result: types.ExperienceResult)
	const results = db.get_results()
	const id = result.universe_id

	assert(id, "missing universe id")

	const idx = table.find(results.unused_experiences, id)

	if results.map_key_experience[key] then
		const old_id = results.map_key_experience[key]
		const old_experience = results.experience_results[tostring(old_id)]

		print(styles.detail(`marked old universe id {old_experience.universe_id} as unused`))
		if old_experience and old_experience.universe_id and old_experience.universe_id ~= result.universe_id then
			table.insert(results.unused_experiences, old_experience.universe_id :: number)
		end
	end

	-- do nothing since the id wasn't in the unused experiences list (probably a new experience)
	results.map_key_experience[key] = id
	results.experience_results[tostring(id)] = result

	if idx == nil then
		db.set_results(results)
		return
	end

	table.remove(results.unused_experiences, idx)
	db.set_results(results)
	print("used experience id")
end

function db.unuse_id(key: string)
	const results = db.get_results()
	const experience_id = results.map_key_experience[key]

	if experience_id then
		results.map_key_experience[key] = nil
		table.insert(results.unused_experiences, experience_id)

		db.set_results(results)
	else
		print(styles.warning(`unable to find associated experience for key {key}`))
	end
end

return db
