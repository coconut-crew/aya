const path = require("@std/path")
const replace_ext = require("@aya/common/utils/replace_ext")
const test = require("@std/test")

const function replaced(input: string, new_ext: string): string
	return path.format(replace_ext(path.parse(input), new_ext))
end

const function expected(input: string): string
	return path.format(path.parse(input))
end

test.suite("replace_ext", function(suite)
	suite:case("replaces the extension and keeps the directory", function(t)
		t.eq(replaced("src/main.luau", "dd"), expected("src/main.dd"))
	end)

	suite:case("accepts an extension with a leading dot", function(t)
		t.eq(replaced("src/main.luau", ".dd"), expected("src/main.dd"))
	end)

	suite:case("strips the extension when given an empty string", function(t)
		t.eq(replaced("src/main.luau", ""), expected("src/main"))
	end)

	suite:case("adds an extension to a file without one", function(t)
		t.eq(replaced("src/Makefile", "bak"), expected("src/Makefile.bak"))
	end)

	suite:case("only replaces the last extension", function(t)
		t.eq(replaced("dist/archive.tar.gz", "zip"), expected("dist/archive.tar.zip"))
	end)

	suite:case("works on a bare file name", function(t)
		t.eq(replaced("main.luau", "dd"), expected("main.dd"))
	end)
end)
