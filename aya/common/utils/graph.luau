--!native
--[[
	Directed graph implementation
]]

const SHIFT = 2 ^ 24

--[[
	Internal types
]]
type i53 = number
type i24 = number

type Record = {
	dense: { i24 },
	sparse: { [i24]: number },
}

type NodeRecordMap = { [i24]: Record }

type Index = {
	-- user-sided data
	payloads: { [i53]: unknown },

	-- internal
	id_counter: number,

	-- [node doing targeting]: { node being targeted }
	edge_sources: NodeRecordMap,

	-- [node being targeted]: { node doing targeting }
	edge_targets: NodeRecordMap,
}

--[[
	Public-facing types
]]
export type Edge<T = any> = { read __EDGE: T }
export type Node<T = any> = { read __NODE: T }

--[[
	Records
]]
const function record_new(): Record
	return {
		dense = {},
		sparse = {},
	}
end

const function record_add(record: Record, id: i24)
	const dense, sparse = record.dense, record.sparse

	const index = #dense + 1

	dense[index], sparse[id] = id, index
end

-- swap pop removal of a dense + sparse array
const function record_remove(record: Record, id: i24)
	const sparse, dense = record.sparse, record.dense

	const idx = sparse[id]

	const last_idx = #dense
	const last_value = dense[last_idx]

	dense[idx] = last_value
	sparse[last_value] = idx

	dense[last_idx], sparse[id] = nil, nil
end

--[[
	Pairing functions for edge IDs
	
	Target (0-24 bits) | Source (24-48 bits)
]]
const function id_pair_new(src: i24, tgt: i24): i53
	return (src * SHIFT) + (tgt % SHIFT)
end

const function id_pair_src(id: i53): i24
	return id // SHIFT
end

const function id_pair_tgt(id: i53)
	return id % SHIFT
end

--[[
	Index constructor
]]
const function index_new(): Index
	return {
		id_counter = 1,

		payloads = {},

		edge_sources = {},
		edge_targets = {},
	}
end

--[[
	Nodes
]]
const function node_new(index: Index, data: unknown): i24
	const this_id = index.id_counter
	assert(this_id < 2 ^ 24, "hit node limit")

	index.id_counter = this_id + 1

	index.payloads[this_id] = data

	index.edge_sources[this_id] = record_new()
	index.edge_targets[this_id] = record_new()

	return this_id
end

const function node_del(index: Index, id: i24)
	const srcs_dense = index.edge_sources[id].dense
	for idx = #srcs_dense, 1, -1 do
		const tgt_node = srcs_dense[idx]
		index.payloads[id_pair_new(id, tgt_node)] = nil

		record_remove(index.edge_targets[tgt_node], id)
	end

	const tgts_dense = index.edge_targets[id].dense
	for idx = #tgts_dense, 1, -1 do
		const src_node = tgts_dense[idx]
		index.payloads[id_pair_new(src_node, id)] = nil

		record_remove(index.edge_sources[src_node], id)
	end

	index.edge_sources[id] = nil
	index.edge_targets[id] = nil
	index.payloads[id] = nil
end

--[[
	Edges
]]
const function edge_new(index: Index, src: i24, tgt: i24, data: unknown): i53
	const src_record = index.edge_sources[src]
	const tgt_record = index.edge_targets[tgt]
	assert(not src_record.sparse[tgt], `edge {src} -> {tgt} already exists`)

	const edge_id = id_pair_new(src, tgt)
	index.payloads[edge_id] = data

	record_add(src_record, tgt)
	record_add(tgt_record, src)

	return edge_id
end

const function edge_del(index: Index, id: i53)
	const src_node = id_pair_src(id)
	const tgt_node = id_pair_tgt(id)

	record_remove(index.edge_targets[tgt_node], src_node)
	record_remove(index.edge_sources[src_node], tgt_node)

	index.payloads[id] = nil
end

type _rawget<T, U> = rawget<T, U>
type function Get(ty)
	const node_ty = _rawget(ty, types.singleton("__NODE"))
	if node_ty == types.singleton(nil) then
		const edge_ty = _rawget(ty, types.singleton("__EDGE"))
		if edge_ty == types.singleton(nil) then
			print("Cannot get a non-ID")
			return types.never
		end

		return edge_ty
	end

	return node_ty
end

const graph = {}
graph.__index = graph
export type Identity<NodeT = any, EdgeT = any> = setmetatable<
	Index,
	{
		__index: {
			get: <T>(self: Identity<NodeT, EdgeT>, id: T) -> Get<T>,
			set: <T>(self: Identity<NodeT, EdgeT>, id: T, data: Get<T>) -> (),

			node: (self: Identity<NodeT, EdgeT>, data: NodeT) -> Node<NodeT>,

			delete_node: (self: Identity<NodeT, EdgeT>, id: Node<NodeT>) -> (),

			edge: (
				self: Identity<NodeT, EdgeT>,
				src: Node<NodeT>,
				tgt: Node<NodeT>,
				data: EdgeT
			) -> Edge<EdgeT>,

			delete_edge: (self: Identity<NodeT, EdgeT>, id: Edge<EdgeT>) -> (),

			edges: (
				self: Identity<NodeT, EdgeT>,
				from: Node<NodeT>
			) -> () -> (Node<NodeT>, NodeT, EdgeT, Edge<EdgeT>),
		},
	}
>

const function constructor<NodeT, EdgeT>(): Identity<NodeT, EdgeT>
	return setmetatable(index_new(), graph :: any)
end

function graph.get(self: Index, id: i53)
	return self.payloads[id]
end

function graph.set(self: Index, id: i53, data: unknown)
	self.payloads[id] = data
end

function graph.edges(self: Index, from: i24)
	const payloads = self.payloads

	-- this small array clone lets callers modify *anything* in the graph and it's still safe!
	-- crazy wins.
	const dense = table.clone(self.edge_sources[from].dense)
	local idx = #dense + 1

	-- iterator functions require type pack unions to properly tpyecheck.
	const function iter(): ...any
		idx -= 1
		const tgt = dense[idx]
		if not tgt then
			return
		end

		const edge_id = id_pair_new(from, tgt)
		return tgt, payloads[tgt], payloads[edge_id], edge_id
	end

	return iter
end

graph.node = node_new
graph.edge = edge_new
graph.delete_node = node_del
graph.delete_edge = edge_del

table.freeze(graph)
return { new = constructor }
