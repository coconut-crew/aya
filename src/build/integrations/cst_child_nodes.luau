const types = require("@std/syntax/types")

-- { kind: tag: (CstNode) -> { CstNode } }
const lookups: { [string]: { [string]: (types.CstNode) -> { types.CstNode } } } = {}

lookups.stat = {
	block = function(node: types.CstStatBlock)
		return node.statements
	end,
	["do"] = function(node: types.CstStatDo)
		return { node.body }
	end,
	conditional = function(node: types.CstStatIf)
		const out: { types.CstNode? } = { node.conditionLocal }
		table.insert(out, node.condition)
		table.insert(out, node.thenBlock)
		for _, clause in node.elseifs do
			table.insert(out, clause.conditionLocal)
			table.insert(out, clause.condition)
			table.insert(out, clause.thenBlock)
		end
		table.insert(out, node.elseBlock)
		return out
	end,
	["while"] = function(node: types.CstStatWhile)
		return { node.condition, node.body }
	end,
	["repeat"] = function(node: types.CstStatRepeat)
		return { node.body, node.condition }
	end,
	["return"] = function(node: types.CstStatReturn)
		const out: { types.CstNode? } = {}
		for _, expression in node.expressions do
			table.insert(out, expression)
		end
		return out
	end,
	expression = function(node: types.CstStatExpr)
		return { node.expression }
	end,
	["local"] = function(node: types.CstStatLocal)
		const out: { types.CstNode? } = {}
		for _, variable in node.variables do
			table.insert(out, variable)
		end
		for _, value in node.values do
			table.insert(out, value)
		end
		return out
	end,
	const = function(node: types.CstStatConst)
		const out: { types.CstNode? } = {}
		for _, variable in node.variables do
			table.insert(out, variable)
		end
		for _, value in node.values do
			table.insert(out, value)
		end
		return out
	end,
	["for"] = function(node: types.CstStatFor)
		return { node.variable, node.from, node.to, node.step, node.body }
	end,
	forin = function(node: types.CstStatForIn)
		const out: { types.CstNode? } = {}
		for _, variable in node.variables do
			table.insert(out, variable)
		end
		for _, value in node.values do
			table.insert(out, value)
		end
		table.insert(out, node.body)
		return out
	end,
	assign = function(node: types.CstStatAssign)
		const out: { types.CstNode? } = {}
		for _, variable in node.variables do
			table.insert(out, variable)
		end
		for _, value in node.values do
			table.insert(out, value)
		end
		return out
	end,
	compoundassign = function(node: types.CstStatCompoundAssign)
		return { node.variable, node.value }
	end,
	["function"] = function(node: types.CstStatFunction)
		return { node.name, node.func }
	end,
	localfunction = function(node: types.CstStatLocalFunction)
		return { node.name, node.func }
	end,
	typealias = function(node: types.CstStatTypeAlias)
		const out: { types.CstNode? } = {}
		if node.generics then
			for _, generic in node.generics do
				table.insert(out, generic.default)
			end
		end
		if node.genericPacks then
			for _, pack in node.genericPacks do
				table.insert(out, pack.default)
			end
		end
		table.insert(out, node.type)
		return out
	end,
	typefunction = function(node: types.CstStatTypeFunction)
		return { node.body }
	end,
}

lookups.expr = {
	group = function(node: types.CstExprGroup)
		return { node.expression }
	end,

	call = function(node: types.CstExprCall)
		const out: { types.CstNode? } = { node.func }
		for _, argument in node.arguments do
			table.insert(out, argument)
		end
		return out
	end,

	instantiate = function(node: types.CstExprInstantiate)
		const out: { types.CstNode? } = { node.expr }
		for _, argument in node.typeArguments do
			table.insert(out, argument)
		end
		return out
	end,
	indexname = function(node: types.CstExprIndexName)
		return { node.expression }
	end,
	index = function(node: types.CstExprIndexExpr)
		return { node.expression, node.index }
	end,
	["function"] = function(node: types.CstExprFunction)
		const out: { types.CstNode? } = {}
		for _, attribute in node.attributes do
			table.insert(out, attribute)
		end
		for _, generic in node.generics do
			table.insert(out, generic.default)
		end
		for _, pack in node.genericPacks do
			table.insert(out, pack.default)
		end
		for _, parameter in node.parameters do
			table.insert(out, parameter)
		end
		table.insert(out, node.varargAnnotation)
		table.insert(out, node.returnAnnotation)
		table.insert(out, node.body)
		return out
	end,
	table = function(node: types.CstExprTable)
		const out: { types.CstNode? } = {}
		for _, item in node.entries do
			if item.kind == "general" then
				table.insert(out, item.key)
			end
			table.insert(out, item.value)
		end
		return out
	end,
	unary = function(node: types.CstExprUnary)
		return { node.operand }
	end,
	binary = function(node: types.CstExprBinary)
		return { node.lhsOperand, node.rhsOperand }
	end,
	interpolatedstring = function(node: types.CstExprInterpString)
		return node.expressions
	end,
	cast = function(node: types.CstExprTypeAssertion)
		return { node.operand, node.annotation }
	end,
	conditional = function(node: types.CstExprIfElse)
		const out: { types.CstNode? } = { node.conditionLocal }
		table.insert(out, node.condition)
		table.insert(out, node.thenExpr)
		for _, clause in node.elseifs do
			table.insert(out, clause.conditionLocal)
			table.insert(out, clause.condition)
			table.insert(out, clause.thenExpr)
		end
		table.insert(out, node.elseExpr)
		return out
	end,
}

lookups.type = {
	reference = function(node: types.CstTypeReference)
		const out: { types.CstNode? } = {}
		if node.parameters then
			for _, parameter in node.parameters do
				table.insert(out, parameter)
			end
		end
		return out
	end,
	typeof = function(node: types.CstTypeTypeof)
		return { node.expression }
	end,
	group = function(node: types.CstTypeGroup)
		return { node.type }
	end,
	union = function(node: types.CstTypeUnion)
		const out: { types.CstNode? } = {}
		for _, option in node.types do
			table.insert(out, option)
		end
		return out
	end,
	intersection = function(node: types.CstTypeIntersection)
		const out: { types.CstNode? } = {}
		for _, part in node.types do
			table.insert(out, part)
		end
		return out
	end,
	array = function(node: types.CstTypeArray)
		return { node.type }
	end,
	table = function(node: types.CstTypeTable)
		const out: { types.CstNode? } = {}
		for _, item in node.entries do
			if item.kind == "indexer" then
				table.insert(out, item.key)
			end
			table.insert(out, item.value)
		end
		return out
	end,
	["function"] = function(node: types.CstTypeFunction)
		const out: { types.CstNode? } = {}
		if node.generics then
			for _, generic in node.generics do
				table.insert(out, generic.default)
			end
		end
		if node.genericPacks then
			for _, pack in node.genericPacks do
				table.insert(out, pack.default)
			end
		end
		for _, parameter in node.parameters do
			table.insert(out, parameter.type)
		end
		table.insert(out, node.vararg)
		table.insert(out, node.returnTypes)
		return out
	end,
}

lookups.typepack = {
	explicit = function(node: types.CstTypePackExplicit)
		const out: { types.CstNode? } = {}
		for _, member in node.types do
			table.insert(out, member)
		end
		table.insert(out, node.tailType)
		return out
	end,
	variadic = function(node: types.CstTypePackVariadic)
		return { node.type }
	end,
}

lookups["local"] = {
	["local"] = function(node: types.CstLocal)
		return { node.annotation }
	end,
}

for _, v in lookups do
	table.freeze(v)
end

return table.freeze(lookups)
