local types = require("../types")

const function create_template()
	return {
		version = 0,
		unused_experiences = {} :: { number },
		map_key_experience = {} :: { [string]: number },
		experience_results = {} :: { [string]: types.ExperienceResult },
	}
end

export type Template = typeof(create_template())

return create_template
