const template = "xxxx-xxxxxxxxxxxx"

const function generate_uuid()
	return (string.gsub(template, "x", function()
		return string.char(math.random(97, 122))
	end))
end

return generate_uuid
