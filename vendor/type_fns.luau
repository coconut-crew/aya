export type function StripMetatable(t: type)
	return types.newtable(t:properties(), t:indexer())
end

type function _CombineTableAndSetIndexer(a: type, b: type, value: type, idx: type)
	local t = {}

	for key, value in a:properties() do
		t[key] = value.read
	end

	if b.tag == "table" then
		for key, value in b:properties() do
			if t[key] then
				error(`Overlapping properties! {key:value()}`)
			end
			t[key] = value.read
		end
	end

	if value == types.never then
		return types.newtable(t :: any)
	end

	return types.newtable(t :: any, { index = idx, readresult = value, writeresult = value })
end
export type CombineTableAndSetIndexer<a, b, value = never, idx = number> = _CombineTableAndSetIndexer<a, b, value, idx>

type function _CombineTables(a: type, others: type)
	local output = types.copy(a)
	local other_types = others:parameters().head or {}
	for _, other_type in other_types do
		for key, value in other_type:properties() do
			output:setproperty(key, value.read)
		end
	end
	return output
end
export type Extend<a, other...> = _CombineTables<a, (other...) -> ()>

export type function negate(t: type): type
	return types.negationof(t)
end

export type function GenerateIdentifiers(prefix: type, elements: type)
	local union = {}
	for key in elements:properties() do
		table.insert(union, types.singleton(`{prefix:value()}:{key:value()}`))
	end
	return types.unionof(table.unpack(union))
end

export type function CombineContent(content_files: type, category_to_type_map: type)
	local thing = {}
	local map = {}

	for category, type in category_to_type_map:properties() do
		map[category:value()] = type.read
	end

	for key, value in content_files:properties() do
		if not value.read then
			continue
		end

		local prefix = key:value()

		for item in value.read:properties() do
			local id = item:value()

			thing[types.singleton(`{prefix}:{id}`)] = map[prefix]
		end
	end

	return types.newtable(thing)
end

export type function TaggedUnionToCallbackOverload(union: type, discriminator: type)
	local overloads = {}
	for _, component in union:components() do
		local discrim_value = component:readproperty(discriminator)
		assert(discrim_value, "discrim didnt exist")

		table.insert(
			overloads,
			types.newfunction({
				head = { discrim_value, types.newfunction({ head = { component } }) },
			})
		)
	end

	return types.intersectionof(table.unpack(overloads))
end

export type function NarrowTaggedUnion(union: type, discriminator: type, which: type)
	local elements = {}

	for _, component in union:components() do
		local ty = component:readproperty(discriminator)
		if ty ~= which then
			continue
		end

		return component
	end

	return types.unionof(table.unpack(elements))
end

export type function ExtractTaggedUnion(union: type, discriminator: type)
	if discriminator == types.any then
		return types.any
	end

	local elements = {}

	for _, component in union:components() do
		for key, value in component:properties() do
			if key:value() ~= discriminator:value() then
				continue
			end

			table.insert(elements, value.read)
		end
	end

	return types.unionof(table.unpack(elements))
end

export type function RemoveLiteralFromUnion(union: type, to_remove: type)
	local elements: { type } = {}

	for _, component in union:components() do
		if component == to_remove then
			continue
		end

		table.insert(elements, component)
	end

	return types.unionof(table.unpack(elements))
end

export type function IdentifierGenericForm(string_literal: type, map: type)
	assert(string_literal.tag == "singleton", "need singleton")
end

export type function ExtractReplicatedType(GamemodeIntersection: type)
	assert(GamemodeIntersection.tag == "union")

	local new_intersection = {}

	for _, element in GamemodeIntersection:components() do
		local new_properties = {}

		for property_ty, value_ty in element:properties() do
			if property_ty:value() ~= "gamemode" and property_ty:value() ~= "replicated" then
				continue
			end

			new_properties[property_ty] = value_ty.read
		end

		table.insert(new_intersection, types.newtable(new_properties :: any))
	end

	return types.unionof(table.unpack(new_intersection))
end

export type function ExtractFirstParameter(t: type)
	assert(t.tag == "function")

	local head = t:parameters().head

	if not head then
		return types.singleton(nil)
	else
		return head[1]
	end
end

export type function IndexForKey(tbl: type, idx: type)
	local new_props = types.newtable()

	for key, prop in tbl:properties() do
		local read, write = prop.read, prop.write

		if write and read and read == write then
			new_props:setproperty(key, read:readproperty(idx) or read:writeproperty(idx))
			continue
		end

		if read and read.tag == "table" then
			new_props:setreadproperty(key, read:readproperty(idx) or read:writeproperty(idx))
		end

		if write and write.tag == "table" then
			new_props:setwriteproperty(key, write:readproperty(idx) or write:writeproperty(idx))
		end
	end

	return new_props
end

export type function ForValues(tbl: type, generic: type)
	local new_props = types.newtable()

	local ret = generic:returns()
	local head = assert(ret.head, "no head type")
	local template = head[1]

	assert(generic.tag == "function")

	local function replace_value(working_type: type, passed_value: type): type
		if working_type.tag == "table" then
			for key, value in working_type:properties() do
				local read, write = value.read, value.write

				if read and write then
					working_type:setproperty(key, replace_value(read, passed_value))
					continue
				end

				if read and read.tag == "generic" and read:name() == "V" then
					working_type:setreadproperty(key, replace_value(read, passed_value))
				end
				if write and write.tag == "generic" and write:name() == "V" then
					working_type:setwriteproperty(key, replace_value(write, passed_value))
				end
			end
			return working_type
		elseif working_type.tag == "union" then
			local new_components = {}
			for _, component in working_type:components() do
				table.insert(new_components, replace_value(component, passed_value))
			end
			return types.unionof(table.unpack(new_components))
		elseif working_type.tag == "intersection" then
			local new_components = {}
			for _, component in working_type:components() do
				table.insert(new_components, replace_value(component, passed_value))
			end
			return types.intersectionof(table.unpack(new_components))
		elseif working_type.tag == "generic" and working_type:name() == "V" then
			return passed_value
		elseif working_type.tag == "function" then
			local params = working_type:parameters()
			if params.head then
				for idx, param_head in params.head do
					params.head[idx] = replace_value(param_head, passed_value)
				end
			elseif params.tail then
				params.tail = replace_value(params.tail, passed_value)
			end

			working_type:setparameters(params.head, params.tail)

			local rets = working_type:returns()
			if rets.head then
				for idx, ret_head_param in rets.head do
					rets.head[idx] = replace_value(ret_head_param, passed_value)
				end
			elseif rets.tail then
				rets.tail = replace_value(rets.tail, passed_value)
			end

			working_type:setreturns(rets.head, rets.tail)

			return working_type
		elseif working_type.tag == "nil" then
			return types.singleton(nil)
		else
			error("unimplemented type: " .. working_type.tag)
		end
	end

	for key, prop in tbl:properties() do
		local read, write = prop.read, prop.write

		if write and read and read == write then
			new_props:setproperty(key, replace_value(types.copy(template), read))
			continue
		end

		if read and read.tag == "table" then
			new_props:setreadproperty(key, replace_value(types.copy(template), read))
		end

		if write and write.tag == "table" then
			new_props:setwriteproperty(key, replace_value(types.copy(template), write))
		end
	end

	return new_props
end

export type function ExtractVfxTableIntoStringIndexUnion(vfx_table: type)
	assert(vfx_table.tag == "table")

	local strs = {}

	for namespace_prop, namespace_value in vfx_table:properties() do
		for func_prop in assert(namespace_value.read):properties() do
			table.insert(strs, types.singleton(`{namespace_prop:value()}.{func_prop:value()}`))
		end
	end

	return types.unionof(table.unpack(strs))
end

export type function GetVfxStringIntoCallData(vfx_table: type, str: type)
	local stringleton = str:value()
	assert(type(stringleton) == "string")

	local arr = string.split(stringleton, ".")
	local namespace, func = arr[1], arr[2]

	local namespace_ty = vfx_table:readproperty(types.singleton(namespace))
	assert(namespace_ty, `no namespace found named {namespace}`)

	local func_ty = namespace_ty:readproperty(types.singleton(func))
	assert(func_ty, `no fx function found in namespace {namespace} named {func}`)

	assert(func_ty.tag == "function", "fx function is nto function " .. func)

	return ExtractFirstParameter(func_ty)
end

export type function FilterStringUnionMustInclude(union: type, literal: type)
	local to_include = {}

	if union.tag ~= "union" then
		return types.singleton("")
	end

	for _, component in union:components() do
		if string.match(component:value() :: string, literal:value() :: string) then
			table.insert(to_include, literal)
		end
	end

	if #to_include == 0 then
		return types.singleton("")
	end

	return types.unionof(table.unpack(to_include))
end

export type function UnionTablePropertiesWith(tbl: type, other: type): type
	local new_props = types.newtable()

	for key, prop in tbl:properties() do
		local read, write = prop.read, prop.write

		if read and write then
			new_props:setproperty(key, types.unionof(types.optional(write), other))
		elseif read then
			new_props:setreadproperty(key, types.unionof(types.optional(read), other))
		elseif write then
			new_props:setwriteproperty(key, types.unionof(types.optional(write), other))
		end
	end

	return new_props
end

export type function DeepTableMerge(a: type, b: type)
	local output = types.copy(a)
	for key, value in b:properties() do
		local read, write = value.read, value.write
		local existing = output:readproperty(key)
		if not read then
			continue
		end
		if not existing then
			if write then
				output:setproperty(key, write)
			else
				output:setreadproperty(key, read)
			end
		elseif existing.tag == "table" and read.tag == "table" then
			local merged = DeepTableMerge(existing, read)
			if write then
				output:setproperty(key, merged)
			else
				output:setreadproperty(key, merged)
			end
		else -- if existing ~= read then
			error(`cannot merge prop {key:value()} of type '{read.tag}' with existing type '{existing.tag}'`)
		end
	end
	return output
end

return nil
