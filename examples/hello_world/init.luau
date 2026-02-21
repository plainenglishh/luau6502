local fs = require("@lune/fs")
local stdio = require("@lune/stdio")
local mos6502 = require("../src")

local bus = mos6502.bus.from_map({
	{
		type = "io",
		start = 0x6000,
		size = 1,
		read = function()
			return 0
		end,
		write = function(addr, value)
			stdio.write(string.char(value))
		end,
	},
	{
		type = "buffer",
		start = 0xFF00,
		size = 256,
		mode = "rom",
		buffer = buffer.fromstring(fs.readFile("examples/hello_world/hello_world.bin")),
	},
})

local cpu = mos6502.cpu.create(bus)

while true do
	if cpu.jammed then
		print("cpu jammed")
		break
	end
	mos6502.cpu.step(cpu, bus)
end
