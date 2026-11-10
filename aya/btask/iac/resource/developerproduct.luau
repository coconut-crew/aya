const formdata = require("../formdata")
const fs = require("@std/fs")
const hash_icon = require("../hash_icon")
const json = require("@vendor/json")
const net = require("@std/net")
const path = require("@std/path")
const request = require("../request")
const styles = require("../../styles")
const types = require("../types")
const universe = require("./universe")

local developerproduct = {}

const function get_form(gamepass: types.DeveloperProduct)
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

function developerproduct.find_product_id(universe_id: number, product: types.DeveloperProduct): number?
	print(styles.detail(`attempting to find developer product under {universe_id} with name {product.name}`))
	const response = request.request(
		"GET",
		`https://apis.roblox.com/developer-products/v2/universes/{universe_id}/developer-products/creator`,
		"",
		{}
	)

	if response.ok then
		const result = json.deserialize(response.body)

		for _, looking in result.developerProducts do
			if looking.name == product.name then
				print(styles.success(`found developer product with id {looking.productId}`))
				return looking.productId
			end
		end

		print(styles.error(`unable to find a developer product`))
		return nil
	end

	print(styles.error(`failed to get results`))
	print(styles.error(`{response.status} {response.body}`))

	return nil
end

-- needs developer-product:write
function developerproduct.create(
	universe_id: number,
	product: types.DeveloperProduct,
	retry_managed_pricing: boolean?
): { ok: true, product_id: number } | { ok: false, response: net.Response }
	print(styles.detail(`creating new developer product under {universe_id} for {product.name}`))
	const form = get_form(product)
	const response = request.request(
		"POST",
		`https://apis.roblox.com/developer-products/v2/universes/{universe_id}/developer-products`,
		form:getBody(),
		{ ["Content-Type"] = form:getHeader() }
	)

	if response.ok then
		const product_id = json.deserialize(response.body).productId
		print(styles.success(`successfully created a new product (id={product_id})`))
		return { ok = true, product_id = product_id }
	else
		-- check if there is a developer product with that name already
		print(styles.warning(styles.header(`failed to create developer product {product.name} on universe {universe_id}`)))
		print(styles.warning(`{response.status} {response.body}`))

		if response.body:find("Managed pricing must be accepted") and not retry_managed_pricing then
			universe.accept_managed_pricing(universe_id)
			return developerproduct.create(universe_id, product, true)
		end

		const found_product_id = developerproduct.find_product_id(universe_id, product)

		if found_product_id then
			print(styles.success(`found product with name associated to it`))
			return { ok = true, product_id = found_product_id }
		end

		return { ok = false, response = response }
	end
end

-- needs developer-product:write
function developerproduct.update_id(
	universe_id: number,
	product_id: number,
	product: types.DeveloperProduct,
	retry_managed_pricing: boolean?
)
	print(styles.detail(`updating product {product_id} for {product.name}`))
	const form = get_form(product)
	const response = request.request(
		"PATCH",
		`https://apis.roblox.com/developer-products/v2/universes/{universe_id}/developer-products/{product_id}`,
		form:getBody(),
		{ ["Content-Type"] = form:getHeader() }
	)

	if response.ok then
		print(styles.success(`successfully updated`))
		return { ok = true }
	else
		print(
			styles.warning(
				styles.header(`failed to patch developer product {product.name} ({product_id}) on universe {universe_id}`)
			)
		)
		print(styles.warning(`{response.status} {response.body}`))

		if response.body:find("Managed pricing must be accepted") and not retry_managed_pricing then
			print(styles.detail("attempting to accept it"))
			universe.accept_managed_pricing(universe_id)
			return developerproduct.update_id(universe_id, product_id, product, true)
		end

		return { ok = false, response = response }
	end
end

function developerproduct.has_changed(old: types.DeveloperProduct, new: types.DeveloperProduct, old_hash: string): boolean
	const hash = hash_icon.hash(new.icon)

	const change_settings = new.name ~= old.name
		or new.description ~= old.description
		or new.managed_pricing ~= old.managed_pricing
		or new.robux_price ~= old.robux_price
	const change_icon = hash ~= old_hash

	return change_settings or change_icon
end

return developerproduct
