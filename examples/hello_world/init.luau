local luau6502 = require("../src")

local old_log: { number } = {}
local bus = luau6502.bus.from_map({
	{
		type = "io",
		start = 0x6000,
		size = 1,
		read = function()
			return 0
		end,
		write = function(addr, value: number)
			table.insert(old_log, value)
			--zune.io.stdout:write(string.char(value))
		end,
	},
	{
		type = "buffer",
		start = 0xFF00,
		size = 256,
		mode = "rom",
		buffer = zune.fs.readFile("examples/hello_world/hello_world.bin", true),
	},
})

local old_cpu = luau6502.mos6502.create(bus)

local old_start = os.clock()
for i = 1, 1000 do
	luau6502.mos6502.reset(old_cpu, bus)

	while true do
		luau6502.mos6502.step(old_cpu, bus)
		if old_cpu.jammed then
			break
		end
	end
end
local old_stop = os.clock()
print("Old: ", old_stop - old_start)

local new_log = {}
local memory: luau6502.Memory = {
	read_pages = {
		[0xFF + 1] = zune.fs.readFile("examples/hello_world/hello_world.bin", true),
	},
	read_offsets = { [0xFF + 1] = 0 },
	write_pages = {
		[0x60 + 1] = function(address: number, value: number)
			if address == 0x6000 then
				table.insert(new_log, value)
			end
		end,
	},
	write_offsets = {},
}

local new_cpu = luau6502.Wdc65C02.new(memory)

local start = os.clock()
for i = 1, 1000 do
	new_cpu:reset()
	while true do
		new_cpu:step(1000)
		if new_cpu._stopped then
			break
		end
	end
end
local stop = os.clock()
print("New: ", stop - start)

assert(table.concat(old_log) == table.concat(new_log))
