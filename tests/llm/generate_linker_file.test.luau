const fs = require("@std/fs")
const generate_linker_file = require("@src/build/utils/generate_linker_file")
const luau = require("@std/luau")
const path = require("@std/path")
const process = require("@std/process")
const system = require("@std/system")
const test = require("@std/test")

const ROOT = path.join(system.tmpdir(), `aya_linker_test_{process.pid()}`)

local case_count = 0

-- each case gets its own directory so loadModule never sees a module from an earlier case
const function fresh_dir(): path.Path
	case_count += 1

	const dir = path.join(ROOT, tostring(case_count))
	fs.createDirectory(path.join(dir, "links"), { makeParents = true })

	return dir
end

const function write_file(file: path.Path, contents: string)
	fs.createDirectory(path.dirname(file), { makeParents = true })
	fs.writeStringToFile(file, contents)
end

-- links a crate entry point `crate/src/lib/init.luau` containing `source`, returning the linker's path
const function link_init(source: string): path.Path
	const dir = fresh_dir()
	const src = path.join(dir, "crate", "src", "lib", "init.luau")
	const dst = path.join(dir, "links", "lib.luau")

	write_file(src, source)
	generate_linker_file(src, dst)

	return dst
end

const function linker_text(source: string): string
	const linker = link_init(source)

	-- loading checks the linker is valid luau and its require resolves
	luau.loadModule(linker)

	return fs.readFileToString(linker)
end

test.suite("generate_linker_file", function(suite)
	suite:afterAll(function()
		if fs.exists(ROOT) then
			fs.removeDirectory(ROOT, { recursive = true })
		end
	end)

	suite:case("returns the module behind an init.luau entry point", function(t)
		const linker = link_init("return { value = 42 }")

		t.eq(luau.loadModule(linker).value, 42)
	end)

	suite:case("returns the module behind a non-init entry point", function(t)
		const dir = fresh_dir()
		const src = path.join(dir, "crate", "src", "mod.luau")
		const dst = path.join(dir, "links", "mod.luau")
		write_file(src, "return { value = 42 }")

		generate_linker_file(src, dst)

		t.eq(luau.loadModule(dst).value, 42)
	end)

	suite:case("links a source below the linker directory", function(t)
		const dir = fresh_dir()
		const src = path.join(dir, "links", "sub", "init.luau")
		const dst = path.join(dir, "links", "lib.luau")
		write_file(src, "return { value = 42 }")

		generate_linker_file(src, dst)

		t.eq(luau.loadModule(dst).value, 42)
	end)

	suite:case("links an init.luau entry point from its own directory", function(t)
		const dir = fresh_dir()
		const src = path.join(dir, "pkg", "init.luau")
		const dst = path.join(dir, "pkg", "link.luau")
		write_file(src, "return { value = 42 }")

		generate_linker_file(src, dst)

		t.eq(luau.loadModule(dst).value, 42)
	end)

	suite:case("links an init.luau entry point from a child directory", function(t)
		const dir = fresh_dir()
		const src = path.join(dir, "pkg", "init.luau")
		const dst = path.join(dir, "pkg", "sub", "link.luau")
		write_file(src, "return { value = 42 }")
		fs.createDirectory(path.dirname(dst))

		generate_linker_file(src, dst)

		t.eq(luau.loadModule(dst).value, 42)
	end)

	suite:case("links a .lua entry point without its extension", function(t)
		const dir = fresh_dir()
		const src = path.join(dir, "crate", "mod.lua")
		const dst = path.join(dir, "links", "mod.luau")
		write_file(src, "return { value = 42 }")

		generate_linker_file(src, dst)

		t.eq(luau.loadModule(dst).value, 42)
	end)

	suite:case("links an init.lua entry point", function(t)
		const dir = fresh_dir()
		const src = path.join(dir, "crate", "lib", "init.lua")
		const dst = path.join(dir, "links", "lib.luau")
		write_file(src, "return { value = 42 }")

		generate_linker_file(src, dst)

		t.eq(luau.loadModule(dst).value, 42)
	end)

	suite:case("links an entry point whose name starts with a dot", function(t)
		const dir = fresh_dir()
		const src = path.join(dir, "links", ".hidden.luau")
		const dst = path.join(dir, "links", "lib.luau")
		write_file(src, "return { value = 42 }")

		generate_linker_file(src, dst)

		t.eq(luau.loadModule(dst).value, 42)
	end)

	suite:case("re-exports every exported type alias", function(t)
		const output = linker_text("export type A = number\nexport type B = string\nreturn {}")

		t.strContains(output, "export type A = REQUIRED_MODULE.A\n")
		t.strContains(output, "export type B = REQUIRED_MODULE.B\n")
	end)

	suite:case("does not re-export private types", function(t)
		const output = linker_text("type Hidden = number\nreturn {}")

		t.strNotContains(output, "Hidden")
	end)

	suite:case("keeps generic defaults on the alias and forwards only the parameters", function(t)
		const output = linker_text("export type Gen<T, U = string> = { T | U }\nreturn {}")

		t.strContains(output, "export type Gen<T, U = string> = REQUIRED_MODULE.Gen<T, U>\n")
	end)

	suite:case("forwards generic packs with their defaults", function(t)
		const output =
			linker_text("export type Fn<T, A... = ...number> = (T, A...) -> ()\nreturn {}")

		t.strContains(output, "export type Fn<T, A... = ...number> = REQUIRED_MODULE.Fn<T, A...>\n")
	end)

	suite:case("keeps generic defaults that are not plain names", function(t)
		const output = linker_text("export type Gen<T = { string }, U... = (number, string)> = T\nreturn {}")

		t.strContains(output, "export type Gen<T = { string }, U... = (number, string)> = ")
	end)

	suite:case("re-exports type functions with their parameters", function(t)
		const output = linker_text("export type function Pick(a, b)\n\treturn a\nend\nreturn {}")

		t.strContains(output, "export type Pick<a, b> = REQUIRED_MODULE.Pick<a, b>\n")
	end)
end)
