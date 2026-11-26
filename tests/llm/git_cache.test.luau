const git_cache = require("@src/pkg/sources/providers/git/git_cache")
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

	suite:case("keeps the first revision when two tags name the same version", function(t)
		const versions = git_cache.parse_ls_remote(ls_remote_output({
			"rev_a\trefs/tags/v1.0.0",
			"rev_b\trefs/tags/1.0.0",
		}))

		t.eq(versions, { ["1.0.0"] = "rev_a" })
	end)

	suite:case("keys a tag by its normalized version without build metadata", function(t)
		const versions = git_cache.parse_ls_remote(ls_remote_output({
			"rev_a\trefs/tags/v1.0.0+build.5",
		}))

		t.eq(versions, { ["1.0.0"] = "rev_a" })
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

test.suite("git_cache.parse_ref_lookup", function(suite)
	suite:case("returns the commit a branch points at", function(t)
		t.eq(git_cache.parse_ref_lookup(ls_remote_output({ "commit\trefs/heads/main" })), "commit")
	end)

	suite:case("prefers the peeled commit of an annotated tag", function(t)
		const revision = git_cache.parse_ref_lookup(ls_remote_output({
			"tag_object\trefs/tags/v1.0.0",
			"commit\trefs/tags/v1.0.0^{}",
		}))

		t.eq(revision, "commit")
	end)

	suite:case("prefers the first listed ref when a branch and a tag share a name", function(t)
		const revision = git_cache.parse_ref_lookup(ls_remote_output({
			"branch_commit\trefs/heads/v1",
			"tag_commit\trefs/tags/v1",
		}))

		t.eq(revision, "branch_commit")
	end)
	suite:case("returns nothing when the ref does not exist", function(t)
		t.eq(git_cache.parse_ref_lookup(""), nil)
	end)
end)

test.suite("git_cache.remote_cache_key", function(suite)
	suite:case("gives the same key to urls for the same github repository", function(t)
		const key = git_cache.remote_cache_key("https://github.com/ffrostfall/bytenet.git")

		t.eq(git_cache.remote_cache_key("https://github.com/ffrostfall/bytenet"), key)
		t.eq(git_cache.remote_cache_key("https://GitHub.com/FFrostFall/ByteNet/"), key)
	end)

	suite:case("uses sixteen hex digits as the key", function(t)
		const key = git_cache.remote_cache_key("https://github.com/ffrostfall/bytenet")

		t.eq(#key, 16)
		t.eq(string.find(key, "^%x+$") ~= nil, true)
	end)

	suite:case("gives every github protocol and user the same key", function(t)
		const key = git_cache.remote_cache_key("https://github.com/o/r")

		t.eq(git_cache.remote_cache_key("ssh://git@github.com/o/r.git"), key)
		t.eq(git_cache.remote_cache_key("http://github.com/o/r"), key)
	end)

	suite:case("ignores trailing slashes and the git suffix on any host", function(t)
		const key = git_cache.remote_cache_key("https://example.com/o/r")

		t.eq(git_cache.remote_cache_key("https://example.com/o/r.git"), key)
		t.eq(git_cache.remote_cache_key("https://example.com/o/r//"), key)
	end)

	suite:case("lowercases only the host of a non-github remote", function(t)
		const key = git_cache.remote_cache_key("https://example.com/o/r")

		t.eq(git_cache.remote_cache_key("https://EXAMPLE.com/o/r"), key)
		t.neq(git_cache.remote_cache_key("https://example.com/O/R"), key)
	end)

	suite:case("keeps the scheme and userinfo of a non-github remote in the key", function(t)
		const key = git_cache.remote_cache_key("https://example.com/o/r")

		t.neq(git_cache.remote_cache_key("ssh://example.com/o/r"), key)
		t.neq(git_cache.remote_cache_key("https://user@example.com/o/r"), key)
	end)

	suite:case("rejects a remote that is not a url", function(t)
		t.throwsWith("remote not-a-url is not a url", git_cache.remote_cache_key, "not-a-url")
	end)

	suite:case("gives different keys to different repositories", function(t)
		t.neq(
			git_cache.remote_cache_key("https://github.com/ffrostfall/bytenet"),
			git_cache.remote_cache_key("https://github.com/ffrostfall/other")
		)
	end)
end)

test.suite("git_cache.resolve_rev", function(suite)
	suite:case("returns a full commit hash without asking the remote", function(t)
		const hash = string.rep("aB3", 13) .. "c"

		t.eq(git_cache.resolve_rev("file:///aya-test-nonexistent", hash), hash)
	end)

	suite:case("asks the remote for a forty character name that is not a hash", function(t)
		t.throws(git_cache.resolve_rev, "file:///aya-test-nonexistent", string.rep("g", 40))
	end)
end)
