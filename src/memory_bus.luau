--- Opaque representation of a memory bus.
export type MemoryBus = {
	--[=[
		Reads a value from memory.
	
		You should return the last value if the addressed location isn't
		mapped to anything.
	]=]
	read: (address: number) -> number,

	--[=[
		Writes a value to memory.

		This is allowed to silently fail.
	]=]
	write: (address: number, value: number) -> (),
}

local memory_bus = {}

function memory_bus.from_buffer(b: buffer): MemoryBus
	local len = buffer.len(b)
	local last_value = 0

	return {
		read = function(address: number): number
			if address >= len then
				return last_value
			end

			last_value = buffer.readu8(b, address)
			return last_value
		end,

		write = function(address: number, value: number)
			if address >= len then
				return
			end

			buffer.writeu8(b, address, value)
		end,
	}
end

return memory_bus
