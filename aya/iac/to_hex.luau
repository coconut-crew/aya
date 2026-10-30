const hexadecimal = {
	[1] = string.byte("0"),
	[2] = string.byte("1"),
	[3] = string.byte("2"),
	[4] = string.byte("3"),
	[5] = string.byte("4"),
	[6] = string.byte("5"),
	[7] = string.byte("6"),
	[8] = string.byte("7"),
	[9] = string.byte("8"),
	[10] = string.byte("9"),
	[11] = string.byte("A"),
	[12] = string.byte("B"),
	[13] = string.byte("C"),
	[14] = string.byte("D"),
	[15] = string.byte("E"),
	[16] = string.byte("F"),
}

const to_hex = {}

function to_hex.buffer(input: buffer): buffer
	const output = buffer.create(buffer.len(input) * 2)

	for i = 0, buffer.len(input) - 1 do
		const idx = i * 2

		const input_char = buffer.readu8(input, i)
		const upper, lower = bit32.band(input_char, 0b00001111), bit32.band(bit32.rshift(input_char, 4), 0b00001111)

		buffer.writeu8(output, idx, hexadecimal[lower + 1])
		buffer.writeu8(output, idx + 1, hexadecimal[upper + 1])
	end

	return output
end

function to_hex.string(input: buffer): string
	const output = to_hex.buffer(input)

	return buffer.tostring(output)
end

return to_hex
