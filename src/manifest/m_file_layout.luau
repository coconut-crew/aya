--[[
	File layout
	
	Root (with workspace, members, etc.): `aya.toml`
	Packages: `<whatever>.ayapkg.toml`
	Crates: `<whatever>.ayacrate.toml`
]]

const m_file_layout = {}

function m_file_layout.find_root_config() end

function m_file_layout.find_config_hierarchy() end

return table.freeze(m_file_layout)
