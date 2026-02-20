--- Opaque representation of a memory bus.
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
		read: (rel_addr: number) -> number,
		write: (rel_addr: number, value: number) -> (),
	}

export type MemoryMap = { MemoryRegion }

local bus = {}

function bus.mapped(map: MemoryMap): Bus
	-- TODO: fix this!

	local last_value = 0

	local function find_region(addr: number): MemoryRegion?
		for _, region in map do
			if addr >= region.start and addr <= region.start + region.size then
				return region
			end
		end
		return nil
	end

	return {
		read = function(addr: number): number
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
				return region.read(rel_addr)
			end
		end,

		write = function(addr: number, value: number)
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
				region.write(rel_addr, value)
			end
		end,
	}
end

function bus.from_buffer(b: buffer): Bus
	return bus.mapped({
		{
			start = 0,
			size = buffer.len(b),
			type = "buffer",
			buffer = b,
		},
	})
end

return bus
