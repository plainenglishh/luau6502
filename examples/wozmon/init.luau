local fs = require("@lune/fs")
local stdio = require("@lune/stdio")
local mos6502 = require("../src")

local PORT_A = 0
local CONTROL_A = 1
local PORT_B = 2
local CONTROL_B = 3

local input = string.split("FF00.FFFF\r", "")
local input_i = 1
local ready = true

local bus = mos6502.bus.from_map({
	{
		type = "buffer",
		start = 0x0000,
		size = 0x5000,
		mode = "ram",
		buffer = buffer.create(0x5000),
	},
	{
		type = "io",
		start = 0xD010,
		size = 4,
		read = function(addr: number): number
			if addr == PORT_A then
				local key = input[input_i]
				if not key then
					ready = false
					return 0
				end
				input_i += 1
				local byte = bit32.replace(string.byte(key), 1, 7)
				return byte
			elseif addr == CONTROL_A then
				return if ready then 0x80 else 0
			elseif addr == PORT_B then
				return 0
			elseif addr == CONTROL_B then
				return 0x80
			end
			error("")
		end,
		write = function(addr: number, value: number)
			if addr == PORT_A then
				return
			elseif addr == CONTROL_A then
				return
			elseif addr == PORT_B then
				local char = string.char(bit32.replace(value, 0, 7))
				stdio.write(if char == "\r" then "\n" else char)
			elseif addr == CONTROL_B then
				return
			end
		end,
	},
	{
		type = "buffer",
		start = 0xFF00,
		size = 256,
		mode = "rom",
		buffer = buffer.fromstring(fs.readFile("examples/wozmon/WOZMON.bin")),
	},
})

local cpu = mos6502.cpu.create(bus)
while true do
	if cpu.jammed then
		print("\ncpu jammed")
		break
	end
	mos6502.cpu.step(cpu, bus)
	--print(string.format("ran pc=0x%02X", cpu.PC))
end
