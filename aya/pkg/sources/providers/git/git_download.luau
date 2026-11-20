const fs = require("@std/fs")
const log = require("@aya/common/log")
const path = require("@std/path")
const process = require("@std/process")

const git_download = {}

function git_download.download(remote: string, revision: string, at: path.Pathlike)
	-- if we don't do this, git itself will error
	if fs.exists(at) then
		log.trace(`location {path.format(at)} already exists, deleting`)
		fs.removeDirectory(at, {
			recursive = true,
		})
	end

	log.trace(
		`downloading git dependency \{ remote: {remote} revision: {revision} to: {path.format(at)} \}`
	)

	const res = process.run({
		"git",
		"clone",
		"--depth=1",
		`--revision={revision}`,
		"--",
		remote,
		path.format(at),
	})
	assert(
		res.ok,
		`cloning {remote} at {revision} failed with exit code {res.exitcode}: {res.stderr}`
	)

	log.trace(`downloaded {remote} revision {revision} successfully`)
end

return table.freeze(git_download)
