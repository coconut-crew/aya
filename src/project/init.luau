--[[
	contains definitions/records for crates, lints, project-wide paths, etc.
	
	the forward-facing configs for this are in workspace
]]

const exit = require("@src/common/exit")
const path = require("@std/path")
const process = require("@std/process")

const function is_env_var_missing(value: string?): boolean
	return (not value or value == "")
end

local anchor_build_dir: path.Pathlike? = nil
local anchor_workspace_dir: path.Pathlike? = nil

const project = {
	BUILD_DIR_ENV_KEY = "AYA_BUILD_DIR",
	WORKSPACE_DIR_ENV_KEY = "AYA_WORKSPACE_DIR",
}

function project.load_anchors()
	const build_dir_entry = process.env[project.BUILD_DIR_ENV_KEY]
	const workspace_dir_entry = process.env[project.WORKSPACE_DIR_ENV_KEY]

	const missing_build_dir_entry = is_env_var_missing(build_dir_entry)
	const missing_workspace_dir_entry = is_env_var_missing(workspace_dir_entry)

	if missing_build_dir_entry or missing_workspace_dir_entry then
		const missing = {}
		if missing_build_dir_entry then
			table.insert(missing, project.BUILD_DIR_ENV_KEY)
		end
		if missing_workspace_dir_entry then
			table.insert(missing, project.WORKSPACE_DIR_ENV_KEY)
		end

		exit("ANCHOR_ENV_VARS_MISSING", table.concat(missing, ", "))
	end

	anchor_build_dir = path.parse(build_dir_entry)
	anchor_workspace_dir = path.parse(workspace_dir_entry)
end

function project.workspace_dir(): path.Pathlike
	if not anchor_workspace_dir then
		return exit("ASSERTION_FAILED", "expected anchors to be loaded")
	end

	return anchor_workspace_dir
end

function project.build_dir(): path.Pathlike
	if not anchor_build_dir then
		return exit("ASSERTION_FAILED", "expected anchors to be loaded")
	end

	return anchor_build_dir
end

function project.workspace_config() end

function project.pkgs() end

function project.crates() end

return table.freeze(project)
