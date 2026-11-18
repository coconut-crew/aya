--[[
	Heavily modified version of Lute's solver which looks eerily similar to Cargo's solver
	
	MIT License
	
	Copyright (c) 2024–2025 Roblox Corporation
	
	Permission is hereby granted, free of charge, to any person obtaining a copy of
	this software and associated documentation files (the "Software"), to deal in
	the Software without restriction, including without limitation the rights to
	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
	of the Software, and to permit persons to whom the Software is furnished to do
	so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.
	
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
]]

const pkg_id = require("@aya/pkg/utils/pkg_id")
const providers = require("@aya/pkg/sources/providers")
const semver = require("@aya/pkg/utils/semver")
const semver_range = require("@aya/pkg/utils/semver_range")
const version_set = require("@aya/pkg/utils/version_set")

export type Ranges = { [pkg_id.GlobalName]: semver_range.Identity }

export type Resolution = { [pkg_id.GlobalName]: semver.Identity }

type Requirement = {
	range: semver_range.Identity,
	required_by: pkg_id.Identifier | false,
}

type ConstraintSet = { [pkg_id.GlobalName]: { Requirement } }

type DecisionFrame = {
	name: pkg_id.GlobalName,
	candidates: { semver.Identity },
	index: number,
	constraints: ConstraintSet,
	selected: Resolution,
}

const function satisfies_all(version: semver.Identity, requirements: { Requirement }): boolean
	for _, requirement in requirements do
		if not version_set.contains(version_set.from_range(requirement.range), version) then
			return false
		end
	end

	return true
end

const function find_candidates(
	name: pkg_id.GlobalName,
	requirements: { Requirement }
): { semver.Identity }
	const result: { semver.Identity } = {}
	for _, version in providers.get_versions_async(name) do
		if satisfies_all(version, requirements) then
			table.insert(result, version)
		end
	end

	return result
end

const function add_requirements(
	set: ConstraintSet,
	ranges: Ranges,
	required_by: pkg_id.Identifier | false
): ConstraintSet
	const result = table.clone(set)
	for name, range in ranges do
		const merged = table.clone(result[name] or {})
		table.insert(merged, { range = range, required_by = required_by })
		result[name] = merged
	end

	return result
end

const function find_invalid_package(set: ConstraintSet, selected: Resolution): pkg_id.GlobalName?
	local invalid: pkg_id.GlobalName? = nil
	for name, version in selected do
		if satisfies_all(version, set[name]) then
			continue
		end

		if invalid == nil or name < invalid then
			invalid = name
		end
	end

	return invalid
end

const function pick_pending(set: ConstraintSet, selected: Resolution): pkg_id.GlobalName?
	local best: pkg_id.GlobalName? = nil
	local best_count = math.huge
	for name, requirements in set do
		if selected[name] then
			continue
		end

		const count = #find_candidates(name, requirements)
		if count == 0 then
			return name
		end

		if count < best_count or (count == best_count and best and name < best) then
			best, best_count = name, count
		end
	end

	return best
end

const function prefer_locked(
	name: pkg_id.GlobalName,
	candidates: { semver.Identity },
	locked: { [pkg_id.Identifier]: true }
)
	for index, candidate_version in candidates do
		if locked[pkg_id.identifier(name, candidate_version)] then
			table.remove(candidates, index)
			table.insert(candidates, 1, candidate_version)
			return
		end
	end
end

const function describe_conflict(name: pkg_id.GlobalName, requirements: { Requirement }): string
	const lines: { string } = {}
	for _, requirement in requirements do
		const source = requirement.required_by or "root"
		table.insert(lines, `  {semver_range.print(requirement.range)}  (required by {source})`)
	end
	table.sort(lines)

	const body = table.concat(lines, "\n")
	return `version conflict for '{name}': no available version satisfies:\n{body}`
end

const resolver = {}

function resolver.solve(roots: Ranges, locked: { [pkg_id.Identifier]: true }?): Resolution
	const stack: { DecisionFrame } = {}
	local constraints = add_requirements({}, roots, false)
	local selected: Resolution = {}

	local stuck: { name: pkg_id.GlobalName, requirements: { Requirement }, depth: number }? = nil

	while true do
		const invalid_name = find_invalid_package(constraints, selected)
		const name = invalid_name or pick_pending(constraints, selected)
		if name == nil then
			return table.freeze(selected)
		end

		const requirements = constraints[name]
		const candidates = if invalid_name then {} else find_candidates(name, requirements)
		if locked then
			prefer_locked(name, candidates, locked)
		end

		if #candidates > 0 then
			table.insert(stack, {
				name = name,
				candidates = candidates,
				index = 0,
				constraints = constraints,
				selected = selected,
			})
		elseif stuck == nil or #stack < stuck.depth then
			stuck = { name = name, requirements = requirements, depth = #stack }
		end

		local stack_len = #stack
		while stack_len > 0 and stack[stack_len].index == #stack[stack_len].candidates do
			table.remove(stack)
			stack_len -= 1
		end

		const frame = stack[stack_len]
		if frame == nil then
			assert(stuck, "luau")
			error(describe_conflict(stuck.name, stuck.requirements))
		end

		frame.index += 1

		const candidate = frame.candidates[frame.index]
		const dependencies = providers.get_dependencies_async(frame.name, candidate)
		const required_by = pkg_id.identifier(frame.name, candidate)

		selected = table.clone(frame.selected)
		selected[frame.name] = candidate
		constraints = add_requirements(frame.constraints, dependencies, required_by)

		if stuck and stuck.depth > #stack then
			stuck = nil
		end
	end
end

return table.freeze(resolver)
