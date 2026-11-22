--[[
	Implementation of interval sets
	
	[>=1.0.0, <=2.0.0)
	
	Contains functions to normalize interval sets, create them, and basic logic.
	Works with any type that can support ranges (semver, integers, etc.)
]]

export type Comparator<T> = (left: T, right: T) -> boolean

export type Identity<T> = {
	[number]: T,

	read min: T,
	read cmp: Comparator<T>,
}

const interval_set = {}

function interval_set.new<T>(comparator: Comparator<T>, min: T, lo: T?, hi: T?): Identity<T>
	assert(lo == nil or hi == nil or comparator(lo, hi), "interval is empty")
	assert(lo ~= nil or hi == nil, "interval has an upper bound but no lower bound")

	return { cmp = comparator, min = min, lo, hi }
end

function interval_set.constructor_with<T>(cmp: Comparator<T>, min: T): (lo: T?, hi: T?) -> Identity<T>
	const function new(lo: T?, hi: T?): Identity<T>
		return interval_set.new(cmp, min, lo, hi)
	end

	return new
end

function interval_set.is_empty<T>(self: Identity<T>): boolean
	return #self == 0
end

function interval_set.contains<T>(self: Identity<T>, element: T): boolean
	const cmp = self.cmp

	-- inside the set when an odd number of boundaries are at or below the element
	-- We use ipairs to avoid iterating over `min` and `cmp`
	for index, boundary in ipairs(self) do
		if cmp(element, boundary) then
			return index % 2 == 0
		end
	end

	return #self % 2 == 1
end

function interval_set.complement<T>(self: Identity<T>): Identity<T>
	const result = table.clone(self)

	--[[
		AI-generated implementation, scary code. Should probably be rewritten at some point
	]]
	if #self > 0 and not self.cmp(self.min, self[1]) then
		table.remove(result, 1)
	else
		table.insert(result, 1, self.min)
	end

	return result
end

function interval_set.intersect<T>(self: Identity<T>, with: Identity<T>): Identity<T>
	const cmp, min = self.cmp, self.min
	const result: Identity<T> = { min = min, cmp = cmp }

	--[[
		AI-generated implementation, scary code. Should probably be rewritten at some point
	]]
	for left_idx = 1, #self, 2 do
		for right_idx = 1, #with, 2 do
			const left_hand, right_hand = self[left_idx], with[right_idx]

			const lower = if cmp(left_hand, right_hand) then right_hand else left_hand

			const left_hi, right_hi = self[left_idx + 1], with[right_idx + 1]
			const upper = if left_hi and (not right_hi or cmp(left_hi, right_hi))
				then left_hi
				else right_hi

			if upper and not cmp(lower, upper :: any) then
				continue
			end

			table.insert(result, lower)
			if upper then
				table.insert(result, upper)
			end
		end
	end

	return result
end

function interval_set.union<T>(self: Identity<T>, with: Identity<T>): Identity<T>
	return interval_set.complement(
		interval_set.intersect(interval_set.complement(self), interval_set.complement(with))
	)
end

function interval_set.is_full<T>(self: Identity<T>): boolean
	return interval_set.is_empty(interval_set.complement(self))
end

function interval_set.is_subset<T>(self: Identity<T>, of: Identity<T>): boolean
	return interval_set.is_empty(interval_set.intersect(self, interval_set.complement(of)))
end

function interval_set.is_disjoint<T>(self: Identity<T>, with: Identity<T>): boolean
	return interval_set.is_empty(interval_set.intersect(self, with))
end

return interval_set
