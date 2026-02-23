--[=[
	Opaque representation of a memory bus. You can construct this using the 
	`mos6502.bus` library, or by implementing it yourself.
]=]
export type Bus = {
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

--[=[
	A memory region used by `mos6502.bus.from_map`.
]=]
export type MemoryRegion =
	{
		start: number,
		size: number,
		type: "buffer",
		buffer: buffer,
		mode: ("rom" | "ram")?,
	}
	| {
		start: number,
		size: number,
		type: "io",
		read: ((rel_addr: number) -> number)?,
		write: ((rel_addr: number, value: number) -> ())?,
	}

--[=[
	A memory map used by `mos6502.bus.from_map`.
]=]
export type MemoryMap = { MemoryRegion }

local bus = {}

--[=[
	Creates a `Bus` from a memory map.
]=]
function bus.from_map(map: MemoryMap): Bus
	-- TODO! assert regions don't overlap.

	local last_value = 0

	local function find_region(addr: number): MemoryRegion?
		for _, region in map do
			if addr >= region.start and addr < region.start + region.size then
				return region
			end
		end
		return nil
	end

	return {
		read = function(addr: number): number
			--print(string.format("attempt to read 0x%04X", addr))
			local region = find_region(addr)
			if not region then
				return last_value
			end

			local rel_addr = addr - region.start
			if region.type == "buffer" then
				if rel_addr >= buffer.len(region.buffer) then
					return 0
				end

				return buffer.readu8(region.buffer, rel_addr)
			else
				if not region.read then
					return last_value
				end

				return region.read(rel_addr)
			end
		end,

		write = function(addr: number, value: number)
			--print(string.format("attempt to write 0x%02X to 0x%04X", value, addr))
			local region = find_region(addr)
			if not region then
				return
			end

			local rel_addr = addr - region.start
			if region.type == "buffer" then
				if rel_addr >= buffer.len(region.buffer) then
					return
				end

				if region.type == "rom" then
					return
				end

				buffer.writeu8(region.buffer, rel_addr, value)
			else
				if not region.write then
					return
				end

				region.write(rel_addr, value)
			end
		end,
	}
end

--[=[
	Creates a `Bus` that maps to a buffer.
]=]
function bus.from_buffer(b: buffer): Bus
	local last_value = 0
	local len = buffer.len(b)

	return {
		read = function(addr: number): number
			if addr >= len then
				return last_value
			end

			last_value = buffer.readu8(b, addr)
			return last_value
		end,

		write = function(addr: number, value: number)
			if addr >= len then
				return
			end

			buffer.writeu8(b, addr, value)
		end,
	}
end

return bus
