const template = "xxxx-xxxxxxxxxxxx"

const function uuid()
	return (string.gsub(template, "x", function()
		return string.char(math.random(97, 122))
	end))
end

return uuid
