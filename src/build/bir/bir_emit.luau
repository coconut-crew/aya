const bir_types = require("@src/build/bir/bir_types")
const luninjau = require("@pkg/luninjau")
const ninja_rules = require("@src/build/bir/ninja_rules")
const path = require("@std/path")

type File = {
	build_build_ninja: luninjau.NinjaStatBuild,
	build_stats: { luninjau.NinjaStatBuild },
}

const function emit_transform(file: File, stat: bir_types.BirTransformLuauObject)
	const variables = stat.vars

	-- this is where we will do weird stuff with compile configs

	table.insert(file.build_stats, {
		stat = "build" :: "build",
		rule = "transform",

		outputs = { path.format(stat.dst) },
		dependencies = { path.format(stat.src) },

		variables = variables,
	})
end

const function emit_configure_crate(file: File, stat: bir_types.BirLinkCrates)
	const build_ninja_stmt = file.build_build_ninja

	assert(build_ninja_stmt.implicit_outputs)

	table.insert(
		build_ninja_stmt.implicit_outputs,
		path.format(path.join(stat.dir, ".config.luau"))
	)

	for _, pair in stat.links do
		table.insert(file.build_stats, {
			stat = "build" :: "build",
			rule = "linkers",

			dependencies = {
				path.format(pair.src),
			},

			outputs = {
				path.format(pair.link_location),
			},
		})
	end
end

const function emit_compile_bin(file: File, stat: bir_types.BirCompileBinStat)
	table.insert(file.build_stats, {
		stat = "build" :: "build",
		rule = "compile_bin",

		dependencies = { path.format(stat.src) },
		outputs = { path.format(stat.dst) },
	})
end

const bir_emit = {
	stat_emits = {
		compile = emit_transform,
		configure_crate = emit_configure_crate,
		compile_bin = emit_compile_bin,
	},
}

function bir_emit.walk(input: { bir_types.BirStat }): string
	const build_build_ninja_stat: luninjau.NinjaStatBuild = {
		stat = "build",

		outputs = { "build.ninja" },

		implicit_outputs = {},

		rule = "configure",
		dependencies = { ".aya.yaml" },
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

	for _, bir_stat: bir_types.BirStat in input do
		if bir_stat.stat == "transform" then
			emit_transform(file, bir_stat)
		elseif bir_stat.stat == "link_crates" then
			emit_configure_crate(file, bir_stat)
		elseif bir_stat.stat == "compile_bin" then
			emit_compile_bin(file, bir_stat)
		end
	end

	const ninja_stats: { luninjau.NinjaStat } = {
		ninja_rules.transform(),
		ninja_rules.configure(),
		ninja_rules.linkers(),
		ninja_rules.compile_bin(),
		ninja_rules.custom_command(),
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
