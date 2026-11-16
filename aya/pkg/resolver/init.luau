--[[
	Heavily modified version of Lute's solver which looks eerily similar to Cargo's solver
	
	todo put license here
]]

const pkg_id = require("@aya/pkg/pkg_id")
const provider = require("@aya/pkg/provider")
const semver = require("@aya/pkg/utils/semver")
const semver_range = require("@aya/pkg/utils/semver_range")
const version_set = require("@aya/pkg/utils/version_set")

export type Ranges = { [pkg_id.GlobalName]: semver_range.Identity }

export type PackageVersion = {
	name: pkg_id.GlobalName,
	version: semver.Identity,
}

export type Resolution = { [string]: PackageVersion }

type Requirement = {
	name: pkg_id.GlobalName,
	range: semver_range.Identity,

	required_by: pkg_id.Identifier | false,
}

type ConstraintSet = { [string]: { Requirement } }

type DecisionFrame = {
	slot: string,
	candidates: { PackageVersion },
	index: number,
	constraints: ConstraintSet,
	selected: Resolution,
}

const function slot_of(name: pkg_id.GlobalName, version: semver.Identity): string
	return `{name}@{semver.compat_key(version)}`
end

const function versions_of(name: pkg_id.GlobalName): { semver.Identity }
	assert(provider.source_for(name), `unknown package '{name}': no source registered`)
	const versions = table.clone(provider.get_versions_async(name))
	table.sort(versions, semver.newer)
	return versions
end

const function satisfies_all(version: semver.Identity, requirements: { Requirement }): boolean
	for _, requirement in requirements do
		if not version_set.contains(version_set.from_range(requirement.range), version) then
			return false
		end
	end

	return true
end

const function find_candidates(requirements: { Requirement }): { PackageVersion }
	const name = requirements[1].name
	const result: { PackageVersion } = {}
	for _, version in versions_of(name) do
		if satisfies_all(version, requirements) then
			table.insert(result, { name = name, version = version })
		end
	end

	return result
end

const function find_slot(name: pkg_id.GlobalName, range: semver_range.Identity): string
	const allowed = version_set.from_range(range)
	for _, version in versions_of(name) do
		if version_set.contains(allowed, version) then
			return slot_of(name, version)
		end
	end

	return slot_of(name, range.version)
end

const function add_requirements(
	set: ConstraintSet,
	ranges: Ranges,
	required_by: pkg_id.Identifier | false
): ConstraintSet
	const result = table.clone(set)
	for name, range in ranges do
		const slot = find_slot(name, range)
		const merged = table.clone(result[slot] or {})
		table.insert(merged, { name = name, range = range, required_by = required_by })
		result[slot] = merged
	end

	return result
end

const function find_invalid_slot(set: ConstraintSet, selected: Resolution): string?
	local invalid: string? = nil
	for slot, package in selected do
		if satisfies_all(package.version, set[slot]) then
			continue
		end

		if invalid == nil or slot < invalid then
			invalid = slot
		end
	end

	return invalid
end

const function pick_pending(set: ConstraintSet, selected: Resolution): string?
	local best: string? = nil
	local best_count = math.huge
	for slot, requirements in set do
		if selected[slot] then
			continue
		end

		const count = #find_candidates(requirements)
		if count == 0 then
			return slot
		end

		if count < best_count or (count == best_count and best and slot < best) then
			best, best_count = slot, count
		end
	end

	return best
end

-- { [identifier]: is locked }
const function prefer_locked(candidates: { PackageVersion }, locked: { [pkg_id.Identifier]: true })
	for index, candidate in candidates do
		if locked[pkg_id.identifier(candidate.name, candidate.version)] then
			table.remove(candidates, index)
			table.insert(candidates, 1, candidate)
			return
		end
	end
end

const function describe_conflict(requirements: { Requirement }): string
	const lines: { string } = {}
	for _, requirement in requirements do
		const source = requirement.required_by or "root"
		table.insert(lines, `  {semver_range.print(requirement.range)}  (required by {source})`)
	end
	table.sort(lines)

	const body = table.concat(lines, "\n")
	return `version conflict for '{requirements[1].name}': no available version satisfies:\n{body}`
end

const resolver = {}

function resolver.solve(roots: Ranges, locked: { [pkg_id.Identifier]: true }?): Resolution
	const stack: { DecisionFrame } = {}
	local constraints = add_requirements({}, roots, false)
	local selected: Resolution = {}

	local stuck: { requirements: { Requirement }, depth: number }? = nil

	while true do
		-- an invalidated selection gets no candidates so it backtracks like any other dead end
		const invalid_slot = find_invalid_slot(constraints, selected)
		const slot = invalid_slot or pick_pending(constraints, selected)
		if slot == nil then
			return table.freeze(selected)
		end

		const requirements = constraints[slot]
		const candidates = if invalid_slot then {} else find_candidates(requirements)
		if locked then
			prefer_locked(candidates, locked)
		end

		if #candidates > 0 then
			table.insert(stack, {
				slot = slot,
				candidates = candidates,
				index = 0,
				constraints = constraints,
				selected = selected,
			})
		else
			if stuck == nil or #stack < stuck.depth then
				stuck = { requirements = requirements, depth = #stack }
			end

			while #stack > 0 and stack[#stack].index == #stack[#stack].candidates do
				table.remove(stack)
			end
		end

		const frame = stack[#stack]
		if frame == nil then
			assert(stuck, "luau")
			error(describe_conflict(stuck.requirements))
		end

		frame.index += 1
		const candidate = frame.candidates[frame.index]
		const dependencies = provider.dependencies_of_async(candidate.name, candidate.version)
		const required_by = pkg_id.identifier(candidate.name, candidate.version)

		selected = table.clone(frame.selected)
		selected[frame.slot] = candidate
		constraints = add_requirements(frame.constraints, dependencies, required_by)

		if stuck and stuck.depth > #stack then
			stuck = nil
		end
	end
end

return table.freeze(resolver)
