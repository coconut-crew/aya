const interval_set = require("@aya/common/utils/interval_set")
const test = require("@std/test")

type Set = interval_set.Identity<number>

const MIN = -math.huge

const function less(left: number, right: number): boolean
	return left < right
end

const function interval(lo: number?, hi: number?): Set
	return interval_set.new(less, MIN, lo, hi)
end

-- the boundary list on its own, without cmp and min
const function boundaries(target: Set): { number }
	return table.move(target, 1, #target, 1, {})
end

test.suite("interval_set.new", function(suite)
	suite:case("includes the lower bound and excludes the upper bound", function(t)
		const target = interval(1, 3)

		t.that(interval_set.contains(target, 1))
		t.that(interval_set.contains(target, 2.5))
		t.never.that(interval_set.contains(target, 3))
		t.never.that(interval_set.contains(target, 0))
	end)

	suite:case("is unbounded above without an upper bound", function(t)
		t.that(interval_set.contains(interval(1), math.huge))
		t.never.that(interval_set.contains(interval(1), 0))
	end)

	suite:case("is empty without bounds", function(t)
		t.that(interval_set.is_empty(interval()))
	end)

	suite:case("rejects an interval with no room between its bounds", function(t)
		t.throwsWith("interval is empty", interval_set.new, less, MIN, 3, 3)
		t.throwsWith("interval is empty", interval_set.new, less, MIN, 5, 3)
	end)
end)

test.suite("interval_set.complement", function(suite)
	suite:case("complements back to the original set", function(t)
		t.eq(boundaries(interval_set.complement(interval_set.complement(interval(1, 3)))), { 1, 3 })
	end)

	suite:case("swaps the empty and full sets", function(t)
		t.that(interval_set.is_full(interval_set.complement(interval())))
		t.that(interval_set.is_empty(interval_set.complement(interval(MIN))))
	end)

	suite:case("keeps the set's comparator and min", function(t)
		const result = interval_set.complement(interval(1, 3))

		t.eq(result.cmp, less)
		t.eq(result.min, MIN)
	end)
end)

test.suite("interval_set.intersect", function(suite)
	suite:case("keeps only the overlap of two intervals", function(t)
		t.eq(boundaries(interval_set.intersect(interval(1, 5), interval(3, 8))), { 3, 5 })
		t.eq(boundaries(interval_set.intersect(interval(3, 8), interval(1, 5))), { 3, 5 })
	end)

	suite:case("bounds an unbounded interval by a bounded one", function(t)
		t.eq(boundaries(interval_set.intersect(interval(2), interval(1, 4))), { 2, 4 })
		t.eq(boundaries(interval_set.intersect(interval(1, 4), interval(2))), { 2, 4 })
	end)

	suite:case("treats touching intervals as not overlapping", function(t)
		t.that(interval_set.is_empty(interval_set.intersect(interval(1, 3), interval(3, 5))))
	end)
end)

test.suite("interval_set.union", function(suite)
	suite:case("merges overlapping and touching intervals", function(t)
		t.eq(boundaries(interval_set.union(interval(1, 3), interval(2, 5))), { 1, 5 })
		t.eq(boundaries(interval_set.union(interval(1, 3), interval(3, 5))), { 1, 5 })
	end)

	suite:case("keeps a gap between separate intervals", function(t)
		const target = interval_set.union(interval(5), interval(1, 2))

		t.eq(boundaries(target), { 1, 2, 5 })
		t.never.that(interval_set.contains(target, 3))
	end)
end)

test.suite("interval_set relations", function(suite)
	suite:case("detects subsets", function(t)
		t.that(interval_set.is_subset(interval(2, 3), interval(1, 5)))
		t.never.that(interval_set.is_subset(interval(1, 5), interval(2, 3)))
	end)

	suite:case("detects disjoint sets", function(t)
		t.that(interval_set.is_disjoint(interval(1, 3), interval(3, 5)))
		t.never.that(interval_set.is_disjoint(interval(1, 4), interval(3)))
	end)
end)
