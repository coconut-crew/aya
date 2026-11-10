const _dev_user = require("@toolingdata/_dev_user")
const cli = require("@batteries/cli")
const db = require("./src/iac/db")
const dev = require("./src/dev")
const iac = require("./src/iac")
const iac_config = require("@toolingdata/iac_config")
const json = require("@std/json")
const net = require("@std/net")
const process = require("@std/process")
const project_decl = require("./project_decl")
const styles = require("./src/styles")
const targets = require("@toolingdata/targets")

const parser = cli.parser()

const HELP = [[
infrastructure as code interface CLI

subcommands:
  ls          lists all keys and experiences currently in use
  publish     publishes a new place onto staging / prod / etc
  universe    gets the universe associated with a key
  info        obtains information about the universe from the db
  unuse       removes the key associated with a place
]]

parser:add("help", "flag", {
	aliases = { "h" },
	help = "Shows this help message",
})

const subcommand = process.args[2]

const function publish_to_webhook(contents: {
	embeds: {
		{
			title: string?,
			color: string?,
			description: string?,
			fields: { { name: string, value: string } }?,
		}
	}?,
})
	const response = net.request(STAGING_IAC_WEBHOOK, {
		method = "POST",
		body = json.serialize(contents :: any),
		headers = {
			["Content-Type"] = "application/json",
			["User-Agent"] = "lute iac tool",
		},
	})

	if response.ok then
		print(styles.success(`published message to webhook`))
	else
		print(styles.error(`failed to publish to webhook, got {response.status} {response.body}`))
	end
end

if subcommand == nil or subcommand == "help" then
	print(HELP)
	process.exit(0)
elseif subcommand == "ls" then
	parser:parse({ table.unpack(process.args, 3) })

	if parser:has("help") then
		print("lists all keys and experiences currently in use")
		parser:help()
		process.exit(0)
	end

	const results = db.get_results()

	print("current active keys:")

	for key, experience_id in results.map_key_experience do
		print(`- {key} - {experience_id}`)
	end

	print()
	print("unused experiences")
	for _, experience_id in results.unused_experiences do
		print(`- {experience_id}`)
	end

	process.exit(0)
elseif subcommand == "unuse" then
	parser:add("key", "variadic", { help = "the key to remove" })

	parser:parse({ table.unpack(process.args, 3) })

	if parser:has("help") or #parser:variadics() == 0 then
		print("marks a key as unused")
		parser:help()
		process.exit(0)
	end

	for _, key in parser:variadics() do
		db.unuse_id(key)
		print(`marked key {key} as unused`)
	end

	publish_to_webhook({
		embeds = {
			{
				title = "Experience is now no longer in use.",
				color = "15277667",
				description = `The experience created for {table.concat(parser:variadics(), ", ")} are no longer in use.`,
			},
		},
	})
elseif subcommand == "universe" then
	parser:add("key", "variadic", { help = "the key to get the universe id for" })

	parser:parse({ table.unpack(process.args, 3) })

	if parser:has("help") then
		parser:help()
		process.exit(0)
	end

	for _, key in parser:variadics() do
		const result = db.get_result(key)
		if result then
			print(result.universe_id)
		end
	end
elseif subcommand == "places" then
	parser:add("key", "variadic", { help = "the universe id to get the places for" })

	parser:parse({ table.unpack(process.args, 3) })

	if parser:has("help") then
		parser:help()
		process.exit(0)
	end

	const places = {}
	const results = db.get_results()
	for _, key in parser:variadics() do
		const result = results.experience_results[key]
		if result then
			for i, place_id in result.place_ids do
				table.insert(places, place_id)
			end
		end
	end

	print(`[{table.concat(places, ",")}]`)
elseif subcommand == "info" then
	parser:add("universe", "variadic", { help = "the universe to get the data for" })

	parser:parse({ table.unpack(process.args, 3) })

	if parser:has("help") then
		parser:help()
		process.exit(0)
	end

	const result = db.get_results()
elseif subcommand == "publish" then
	parser:add("staging", "option", { help = "uses the staging configuration" })
	parser:add("production", "option", { aliases = { "prod" }, help = "uses the production configuration" })
	parser:add(
		"target",
		"option",
		{ default = "dev-default", aliases = { "t" }, help = "the target to configure. by default dev-default" }
	)
	parser:add("key", "positional", { required = true, help = "the key that will be published into" })

	parser:parse({ table.unpack(process.args, 3) })

	if parser:has("help") then
		parser:help()
		process.exit(0)
	end

	const key = parser:get("key")
	const use_production = parser:has("production")

	assert(key, "key is missing")
	const function produce_config(config: iac.ExperienceConfig): iac.ExperienceConfig
		if use_production then
		else
			config.name = `Decaying Winter Staging - {key}`
			config.description = "This is a staging place for Decaying Winter."

			for _, place in config.places do
				place.max_player_count = 50
			end

			if config.products then
				for _, product in config.products do
					if product.robux_price then
						product.robux_price = 1
					end
				end
			end

			if config.gamepasses then
				for _, product in config.gamepasses do
					if product.robux_price then
						product.robux_price = 1
					end
				end
			end
		end

		return config
	end

	const function produce_target(lockfile: iac.ExperienceLockFile): project_decl.target
		const target_key = parser:get("target")
		const target_data = targets[target_key]

		if target_data == nil then
			print(`invalid target {target_key}; use -t to specify a target`)
			process.exit(0)
		end

		for key, place_id in lockfile.place_ids do
			const project = target_data.projects[key]
			if project then
				project.place_id = place_id
				project.universe_id = lockfile.universe_id
			end
		end

		target_data.universe_id = lockfile.universe_id

		const target_config = table.clone(target_data.default_config)

		target_config.BADGES = json.serialize(lockfile.badges :: any)
		target_config.GAMEPASSES = json.serialize(lockfile.gamepasses :: any)
		target_config.PRODUCTS = json.serialize(lockfile.products :: any)

		target_data.default_config = target_config

		return target_data
	end

	const function compile_target(target: project_decl.target, lockfile: iac.ExperienceLockFile, name)
		const dev_session = dev.session({
			user = _dev_user,
			project_id = name,
			target = target,
		})
		dev_session.blink_compile()
		const initialized = dev_session.init()
		const game_rbxl = initialized.rbxl()

		return game_rbxl
	end

	const config = produce_config(iac_config :: iac.ExperienceConfig)
	const previous_config = db.get_result(key)
	const old_config = if previous_config == nil then db.obtain_unused_experience_id() else previous_config
	const new_config = iac.update_experience(config, old_config)
	iac.update_result(key, new_config)

	const experience_id = new_config.universe_id
	const root_place_id = new_config.root_place_id

	if experience_id == nil then
		error(`missing experience`)
	end

	-- the old config did not exist at all, so the universe has to be recreated.
	-- notify developers that they need to config this universe.
	if old_config == nil then
		const UNIVERSE_DASHBOARD_LINK = `https://create.roblox.com/dashboard/creations/experiences/{experience_id}`
		print(
			styles.error(`UNIVERSE {new_config.universe_id} HAS NOT BEEN CONFIGURED. PLEASE CONFIGURE SO TESTERS CAN ACCESS.`)
		)
		print(styles.error(`CONFIGURE HERE: {UNIVERSE_DASHBOARD_LINK}`))

		publish_to_webhook({
			embeds = {
				{
					title = "Attention Required",
					color = "15277667",
					description = `A new experience has been created for {key}. Please configure the maturity settings and access settings to make the experience available to testers.`,
					fields = {
						{
							name = "Questionnaire Link",
							value = `https://create.roblox.com/dashboard/creations/experiences/{experience_id}/experience-questionnaire`,
						},
					},
				},
			},
		})
	end

	const target = produce_target(new_config)

	for name in target.projects do
		iac.publish_to_target(new_config, name, compile_target(target, new_config, name :: any))
	end

	print(styles.success(`successfully published to {experience_id}.`))

	if previous_config == nil and old_config ~= nil then
		publish_to_webhook({
			embeds = {
				{
					title = "New Experience",
					color = "3066993",
					description = `A experience has been setup for {key}.`,
					fields = {
						{
							name = "Join Link",
							value = `https://www.roblox.com/games/start?placeId={root_place_id}`,
						},
						{
							name = "Roblox Link",
							value = `https://www.roblox.com/games/{root_place_id}`,
						},
					},
				},
			},
		})
	else
		publish_to_webhook({
			embeds = {
				{
					title = "Published Successfully",
					color = "15277667",
					description = `A new version has been published for {key}.`,
					fields = {
						{
							name = "Join Link",
							value = `https://www.roblox.com/games/start?placeId={root_place_id}`,
						},
					},
				},
			},
		})
	end
end
