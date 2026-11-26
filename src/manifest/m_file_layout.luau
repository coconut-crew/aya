--[[
	File layout
	
	Root (with workspace, members, etc.): `aya.yaml`
	Packages: `<whatever>.ayapkg.yaml`
	Crates: `<whatever>.ayacrate.yaml`
]]

const m_file_layout = {}

function m_file_layout.find_root_config() end

function m_file_layout.find_config_hierarchy() end

return table.freeze(m_file_layout)
