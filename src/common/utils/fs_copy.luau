const path = require(`@std/path`)
const fs = require(`@std/fs`)

const function file_or_directory(from: path.Pathlike, to: path.Pathlike)
	const filetype = fs.metadata(from).type

	if filetype == `dir` then
		-- listed first so a destination inside the source is not copied into itself
		const entries = fs.listDirectory(from)
		fs.createDirectory(to)

		for _, entry in entries do
			file_or_directory(path.join(from, entry.name), path.join(to, entry.name))
		end
	elseif filetype == `file` then
		fs.copy(from, to)
	else
		error(`unsupported file type: {filetype}`)
	end
end

return {
	file_or_directory = file_or_directory,
}
