const fs = require("@std/fs")
const path = require("@std/path")

const function get_files_under_directory(directory: path.Path, only_files: boolean?, populate: { path.Path }?): { path.Path }
	populate = if populate ~= nil then populate else {}

	const contents = fs.listDirectory(directory)

	for _, entry in contents do
		const joined = path.join(directory, entry.name)

		if entry.type == "dir" then
			if not only_files then
				table.insert(populate, joined)
			end

			get_files_under_directory(joined, only_files, populate)
		else
			table.insert(populate, joined)
		end
	end

	return populate
end

return get_files_under_directory
