const bir_types = require("@aya/build/bir/bir_types")
const luninjau = require("@pkg/luninjau")
const ninja_rules = require("@aya/build/bir/ninja_rules")
const path = require("@std/path")

type File = {
	build_build_ninja: luninjau.NinjaStatBuild,
	build_stats: { luninjau.NinjaStatBuild },
}

const function to_ninja_path(input_path: path.Pathlike)
	return path.format(input_path)
end

const function emit_compile(file: File, stat: bir_types.BirCompileLuauObject)
	const variables = stat.vars

	-- this is where we will do weird stuff with compile configs

	table.insert(file.build_stats, {
		stat = "build" :: "build",
		rule = "compile",

		outputs = { to_ninja_path(stat.dst) },
		dependencies = { to_ninja_path(stat.src) },

		variables = variables,
	})
end

const function emit_configure_crate(file: File, stat: bir_types.BirLinkCrates)
	const build_ninja_stmt = file.build_build_ninja

	assert(build_ninja_stmt.implicit_outputs)

	table.insert(
		build_ninja_stmt.implicit_outputs,
		to_ninja_path(path.join(stat.dir, ".config.luau"))
	)

	for _, pair in stat.links do
		table.insert(file.build_stats, {
			stat = "build" :: "build",
			rule = "linkers",

			dependencies = {
				to_ninja_path(pair.src),
			},

			outputs = {
				to_ninja_path(pair.link_location),
			},
		})
	end
end

const bir_emit = {
	stat_emits = {
		compile = emit_compile,
		configure_crate = emit_configure_crate,
	},
}

function bir_emit.walk(input: { bir_types.BirStat }): string
	const build_build_ninja_stat: luninjau.NinjaStatBuild = {
		stat = "build",

		outputs = { "build.ninja" },

		implicit_outputs = {},

		rule = "configure",
		dependencies = { ".aya.toml" },
		variables = {
			generator = "1",
			restat = "1",
		},
	}

	const file: File = {
		build_build_ninja = build_build_ninja_stat,

		includes = {},

		build_stats = {},

		rules = {},
	}

	for _, bir_stat in input do
		if bir_stat.stat == "compile" then
			emit_compile(file, bir_stat)
		elseif bir_stat.stat == "link_crates" then
			emit_configure_crate(file, bir_stat)
		end
	end

	const ninja_stats: { luninjau.NinjaStat } = {
		ninja_rules.compile(),
		ninja_rules.configure(),
		ninja_rules.linkers(),
	}

	table.insert(ninja_stats, file.build_build_ninja)

	for _, stat in file.build_stats do
		table.insert(ninja_stats, stat)
	end

	return luninjau.print_file({
		stmts = ninja_stats,
	})
end

return bir_emit
