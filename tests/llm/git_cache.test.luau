const git_cache = require("@aya/pkg/sources/providers/git/git_cache")
const test = require("@std/test")

-- joins "revision\tref" lines the way `git ls-remote` prints them
const function ls_remote_output(lines: { string }): string
	return table.concat(lines, "\n") .. "\n"
end

test.suite("git_cache.parse_ls_remote", function(suite)
	suite:case("maps each tagged version to its revision", function(t)
		const versions = git_cache.parse_ls_remote(ls_remote_output({
			"rev_a\trefs/tags/v0.9.0",
			"rev_b\trefs/tags/1.0.0",
			"rev_c\trefs/tags/v1.2.0-beta.1",
		}))

		t.eq(versions, {
			["0.9.0"] = "rev_a",
			["1.0.0"] = "rev_b",
			["1.2.0-beta.1"] = "rev_c",
		})
	end)

	suite:case("uses the peeled commit for annotated tags", function(t)
		const versions = git_cache.parse_ls_remote(ls_remote_output({
			"tag_object\trefs/tags/v1.0.0",
			"commit\trefs/tags/v1.0.0^{}",
		}))

		t.eq(versions, { ["1.0.0"] = "commit" })
	end)

	suite:case("skips tags that are not valid semver", function(t)
		const versions = git_cache.parse_ls_remote(ls_remote_output({
			"rev_a\trefs/tags/latest",
			"rev_b\trefs/tags/v1.0",
			"rev_c\trefs/tags/v01.0.0",
			"rev_d\trefs/tags/v1.0.0",
		}))

		t.eq(versions, { ["1.0.0"] = "rev_d" })
	end)

	suite:case("returns no versions for empty output", function(t)
		t.eq(git_cache.parse_ls_remote(""), {})
	end)
end)

test.suite("git_cache.remote_cache_key", function(suite)
	suite:case("gives the same key to urls for the same github repository", function(t)
		const key = git_cache.remote_cache_key("https://github.com/ffrostfall/bytenet.git")

		t.eq(git_cache.remote_cache_key("https://github.com/ffrostfall/bytenet"), key)
		t.eq(git_cache.remote_cache_key("https://GitHub.com/FFrostFall/ByteNet/"), key)
	end)

	suite:case("gives different keys to different repositories", function(t)
		t.neq(
			git_cache.remote_cache_key("https://github.com/ffrostfall/bytenet"),
			git_cache.remote_cache_key("https://github.com/ffrostfall/other")
		)
	end)
end)
