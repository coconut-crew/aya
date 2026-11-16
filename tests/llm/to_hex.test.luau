const test = require("@std/test")
const to_hex = require("@aya/common/utils/to_hex")

test.suite("to_hex", function(suite)
	suite:case("encodes every byte as two uppercase hex digits, high nibble first", function(t)
		const input = buffer.create(256)
		const expected: { string } = {}

		for byte = 0, 255 do
			buffer.writeu8(input, byte, byte)
			table.insert(expected, string.format("%02X", byte))
		end

		t.eq(to_hex.string(input), table.concat(expected))
	end)

	suite:case("encodes an empty buffer as an empty string", function(t)
		t.eq(to_hex.string(buffer.create(0)), "")
	end)

	suite:case("returns a buffer with the same contents as the string form", function(t)
		const input = buffer.fromstring("lute")

		t.eq(to_hex.buffer(input), buffer.fromstring(to_hex.string(input)))
	end)
end)
