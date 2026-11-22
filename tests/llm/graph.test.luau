const graph = require("@src/common/utils/graph")
const test = require("@std/test")

type Graph = graph.Identity<string, string>
type Node = graph.Node<string>

-- { [target node]: { target data, edge data, edge id } }
const function collect_edges(target: Graph, from: Node): { [Node]: { any } }
	const seen: { [Node]: { any } } = {}
	for tgt, tgt_data, edge_data, edge_id in target:edges(from) do
		seen[tgt] = { tgt_data, edge_data, edge_id }
	end

	return seen
end

test.suite("graph:node", function(suite)
	suite:case("gives each node its own id and stores its data", function(t)
		const target: Graph = graph.new<<string, string>>()

		const a = target:node("a")
		const b = target:node("b")

		t.neq(a, b)
		t.eq(target:get(a), "a")
		t.eq(target:get(b), "b")
	end)
end)

test.suite("graph:set", function(suite)
	suite:case("replaces the data of a node or an edge", function(t)
		const target: Graph = graph.new<<string, string>>()
		const a = target:node("a")
		const b = target:node("b")
		const ab = target:edge(a, b, "a->b")

		target:set(a, "node changed")
		target:set(ab, "edge changed")

		t.eq(target:get(a), "node changed")
		t.eq(target:get(ab), "edge changed")
	end)
end)

test.suite("graph:edge", function(suite)
	suite:case("stores the edge data under the returned id", function(t)
		const target: Graph = graph.new<<string, string>>()
		const a = target:node("a")
		const b = target:node("b")

		const ab = target:edge(a, b, "a->b")

		t.eq(target:get(ab), "a->b")
	end)

	-- node and edge data share one map, so an edge id that equals a node id
	-- would overwrite that node's data
	suite:case("keeps node data intact when edges are added", function(t)
		const target: Graph = graph.new<<string, string>>()
		const a = target:node("a")
		const b = target:node("b")

		target:edge(a, b, "a->b")
		target:edge(b, a, "b->a")
		target:edge(a, a, "a->a")

		t.eq(target:get(a), "a")
		t.eq(target:get(b), "b")
	end)

	suite:case("treats edges as directed", function(t)
		const target: Graph = graph.new<<string, string>>()
		const a = target:node("a")
		const b = target:node("b")

		const ab = target:edge(a, b, "a->b")
		const ba = target:edge(b, a, "b->a")

		t.neq(ab, ba)
		t.eq(target:get(ab), "a->b")
		t.eq(target:get(ba), "b->a")
	end)

	suite:case("rejects an edge that already exists", function(t)
		const target: Graph = graph.new<<string, string>>()
		const a = target:node("a")
		const b = target:node("b")
		const ab = target:edge(a, b, "a->b")

		t.throws(target.edge, target, a, b, "again")
		t.eq(target:get(ab), "a->b")
	end)
end)

test.suite("graph:delete_node", function(suite)
	suite:case("removes the node with its incoming and outgoing edges", function(t)
		const target: Graph = graph.new<<string, string>>()
		const a = target:node("a")
		const b = target:node("b")
		const c = target:node("c")
		const ab = target:edge(a, b, "a->b")
		const bc = target:edge(b, c, "b->c")
		const ac = target:edge(a, c, "a->c")

		target:delete_node(b)

		t.eq(target:get(b), nil)
		t.eq(target:get(ab), nil)
		t.eq(target:get(bc), nil)
		t.eq(target:get(ac), "a->c")
		t.eq(collect_edges(target, a), { [c] = { "c", "a->c", ac } })
	end)

	suite:case("removes a self loop", function(t)
		const target: Graph = graph.new<<string, string>>()
		const a = target:node("a")
		const aa = target:edge(a, a, "a->a")

		target:delete_node(a)

		t.eq(target:get(aa), nil)
	end)

	-- deleting b moves d into b's slot in a's record, so deleting d next
	-- only works if that move was tracked
	suite:case("keeps remaining edges intact when neighbours are deleted out of order", function(t)
		const target: Graph = graph.new<<string, string>>()
		const a = target:node("a")
		const b = target:node("b")
		const c = target:node("c")
		const d = target:node("d")
		target:edge(a, b, "a->b")
		const ac = target:edge(a, c, "a->c")
		target:edge(a, d, "a->d")

		target:delete_node(b)
		target:delete_node(d)

		t.eq(collect_edges(target, a), { [c] = { "c", "a->c", ac } })

		target:delete_node(a)

		t.eq(target:get(ac), nil)
	end)
end)

test.suite("graph:delete_edge", function(suite)
	suite:case("removes the edge but keeps its reverse and both nodes", function(t)
		const target: Graph = graph.new<<string, string>>()
		const a = target:node("a")
		const b = target:node("b")
		const ab = target:edge(a, b, "a->b")
		const ba = target:edge(b, a, "b->a")

		target:delete_edge(ab)

		t.eq(target:get(ab), nil)
		t.eq(target:get(ba), "b->a")
		t.eq(target:get(a), "a")
		t.eq(target:get(b), "b")
		t.eq(collect_edges(target, a), {})
	end)

	suite:case("allows the same edge to be added again", function(t)
		const target: Graph = graph.new<<string, string>>()
		const a = target:node("a")
		const b = target:node("b")
		target:delete_edge(target:edge(a, b, "a->b"))

		const ab = target:edge(a, b, "again")

		t.eq(target:get(ab), "again")
	end)

	-- delete_node walks both nodes' records, so a leftover entry on either
	-- side of the deleted edge would make it fail
	suite:case("leaves both nodes safe to delete afterwards", function(t)
		const target: Graph = graph.new<<string, string>>()
		const a = target:node("a")
		const b = target:node("b")
		const c = target:node("c")
		const ab = target:edge(a, b, "a->b")
		const ac = target:edge(a, c, "a->c")

		target:delete_edge(ab)
		target:delete_node(b)

		t.eq(target:get(ac), "a->c")

		target:delete_node(a)

		t.eq(target:get(ac), nil)
	end)
end)

test.suite("graph:edges", function(suite)
	suite:case("yields each outgoing edge with its target and data", function(t)
		const target: Graph = graph.new<<string, string>>()
		const a = target:node("a")
		const b = target:node("b")
		const c = target:node("c")
		const ab = target:edge(a, b, "a->b")
		const ac = target:edge(a, c, "a->c")
		target:edge(c, a, "c->a")

		t.eq(collect_edges(target, a), {
			[b] = { "b", "a->b", ab },
			[c] = { "c", "a->c", ac },
		})
	end)

	suite:case("yields nothing for a node without outgoing edges", function(t)
		const target: Graph = graph.new<<string, string>>()
		const a = target:node("a")
		const b = target:node("b")
		target:edge(b, a, "b->a")

		t.eq(collect_edges(target, a), {})
	end)

	suite:case("visits every edge when the loop deletes each target", function(t)
		const target: Graph = graph.new<<string, string>>()
		const a = target:node("a")
		target:edge(a, target:node("b"), "a->b")
		target:edge(a, target:node("c"), "a->c")
		target:edge(a, target:node("d"), "a->d")

		local visited = 0
		for tgt in target:edges(a) do
			target:delete_node(tgt)
			visited += 1
		end

		t.eq(visited, 3)
		t.eq(collect_edges(target, a), {})
	end)
end)
