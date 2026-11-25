--[[
	Aya Crate Identifier

	Handles `<package>/<crate>` identifiers
]]

export type RawLocator = string

const m_acl_parser = {}

function m_acl_parser.init() end

return table.freeze(m_acl_parser)
