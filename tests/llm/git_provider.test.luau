const git = require("@aya/pkg/provider/git")
const semver = require("@aya/pkg/utils/semver")
const test = require("@std/test")

-- joins "revision\tref" lines the way `git ls-remote` prints them
const function ls_remote_output(lines: { string }): string
	return table.concat(lines, "\n") .. "\n"
end

test.suite("git.remote_parse_lsremote", function(suite)
	suite:case("returns versions newest first with their revisions", function(t)
		const records = git.remote_parse_lsremote(ls_remote_output({
			"rev_a\trefs/tags/v0.9.0",
			"rev_b\trefs/tags/v1.0.0",
			"rev_c\trefs/tags/v1.2.0",
		}))

		t.eq(records, {
			{ version = semver.parse("1.2.0"), revision = "rev_c" },
			{ version = semver.parse("1.0.0"), revision = "rev_b" },
			{ version = semver.parse("0.9.0"), revision = "rev_a" },
		})
	end)

	suite:case("uses the peeled commit for annotated tags", function(t)
		const records = git.remote_parse_lsremote(ls_remote_output({
			"tag_object\trefs/tags/v1.0.0",
			"commit\trefs/tags/v1.0.0^{}",
		}))

		t.eq(records, {
			{ version = semver.parse("1.0.0"), revision = "commit" },
		})
	end)

	suite:case("accepts tags with and without a v prefix", function(t)
		const records = git.remote_parse_lsremote(ls_remote_output({
			"rev_a\trefs/tags/1.0.0",
			"rev_b\trefs/tags/v2.0.0",
		}))

		t.eq(records, {
			{ version = semver.parse("2.0.0"), revision = "rev_b" },
			{ version = semver.parse("1.0.0"), revision = "rev_a" },
		})
	end)

	suite:case("keeps prerelease tags", function(t)
		const records = git.remote_parse_lsremote(ls_remote_output({
			"rev_a\trefs/tags/v1.0.0-beta.1",
		}))

		t.eq(records, {
			{ version = semver.parse("1.0.0-beta.1"), revision = "rev_a" },
		})
	end)

	suite:case("skips tags that are not valid semver", function(t)
		const records = git.remote_parse_lsremote(ls_remote_output({
			"rev_a\trefs/tags/latest",
			"rev_b\trefs/tags/v1.0",
			"rev_c\trefs/tags/v01.0.0",
			"rev_d\trefs/tags/v1.0.0",
		}))

		t.eq(records, {
			{ version = semver.parse("1.0.0"), revision = "rev_d" },
		})
	end)

	suite:case("keeps one record when two tags name the same version", function(t)
		const records = git.remote_parse_lsremote(ls_remote_output({
			"rev_a\trefs/tags/1.0.0",
			"rev_b\trefs/tags/v1.0.0",
		}))

		t.eq(#records, 1)
	end)

	suite:case("returns no versions for empty output", function(t)
		t.eq(git.remote_parse_lsremote(""), {})
	end)
end)
