const caches = {}
caches.__index = caches
type Identity = setmetatable<{}, typeof(caches)>

const function constructor(): Identity
	const self = setmetatable({}, caches)
	return self
end

table.freeze(caches)
return { new = constructor }
