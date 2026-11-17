const app_dirs = require("@aya/common/app_dirs")
const fs = require("@std/fs")
const path = require("@std/path")

const cache = {}
cache.__index = cache
export type Identity = setmetatable<{
	cache_path: path.Path,

	in_memory: { [string]: string },
}, typeof(cache)>

const function constructor(subpath: path.Pathlike): Identity
	const self = setmetatable({
		in_memory = {},
	}, cache)

	const caches = app_dirs.ensure("cache")
	const this_cache_dir = path.join(caches, subpath)

	if not fs.exists(this_cache_dir) then
		fs.createDirectory(this_cache_dir, { makeParents = true })
	end

	self.cache_path = this_cache_dir

	return self
end

function cache.key_path(self: Identity, key: string): path.Path
	return path.join(self.cache_path, key)
end

function cache.get(self: Identity, key: string): string?
	if self.in_memory[key] then
		return self.in_memory[key]
	else
		const relevant_path = self:key_path(key)
		if not fs.exists(relevant_path) then
			self.in_memory[key] = nil
			return nil
		end

		const content = fs.readFileToString(relevant_path)

		self.in_memory[key] = content
		return content
	end
end

function cache.set(self: Identity, key: string, content: string)
	fs.writeStringToFile(self:key_path(key), content)
	self.in_memory[key] = content
end

table.freeze(cache)
return { new_async = constructor }
