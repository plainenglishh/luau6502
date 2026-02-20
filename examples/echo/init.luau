local fs = require("@lune/fs")
local stdio = require("@lune/stdio")
local mos6502 = require("../src")

local bus = mos6502.memory_bus.mapped({
	{
		type = "buffer",
		start = 0x0000,
		size = 0x5000,
		mode = "ram",
		buffer = buffer.create(0x5000),
	},
	{
		--- recv key
		type = "io",
		start = 0x6000,
		size = 1,
		read = function(addr: number): number
			stdio.write("cpu requests key: ")
			local key = string.byte(stdio.readLine())
			return key
		end,
		write = function(value)
			return
		end,
	},
	{
		type = "io",
		start = 0x6001,
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
		buffer = buffer.fromstring(fs.readFile("examples/echo/echo.bin")),
	},
})

local cpu = mos6502.create(bus)

while true do
	if cpu.jammed then
		print("cpu jammed")
		break
	end
	mos6502.step(cpu, bus)
end
