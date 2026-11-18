const path = require("@std/path")
const process = require("@std/process")

const git_download = {}

function git_download.download(remote: string, revision: string, at: path.Pathlike)
	const res = process.run(
		{ "git", "clone", "--depth=1", `--revision={revision}`, "--", remote, path.format(at) },
		{ stdio = "inherit" }
	)
	assert(res.ok, `cloning {remote} at {revision} failed with exit code {res.exitcode}`)
end

return table.freeze(git_download)
