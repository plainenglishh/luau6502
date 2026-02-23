local mos6502 = require("../src")

local PORT_A = 0
local CONTROL_A = 1
local PORT_B = 2
local CONTROL_B = 3

local key_buffer: { number } = {}

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
				local key = table.remove(key_buffer, 1)
				if not key then
					return 0
				end

				local byte = bit32.replace(key, 1, 7)
				return byte
			elseif addr == CONTROL_A then
				return if #key_buffer ~= 0 then 0x80 else 0
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
				zune.io.stdout:write(if char == "\r" then "\n" else char)
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
		buffer = zune.fs.readFile("examples/wozmon/WOZMON.bin", true),
	},
})

zune.io.terminal.enableRawMode()
zune.task.spawn(function()
	while true do
		local b = zune.io.stdin:read(1, true)
		local key = buffer.readu8(b, 0)
		if key == 0x03 then
			zune.process.exit(0)
		end
		table.insert(key_buffer, key)
	end
end)

local cpu = mos6502.cpu.create(bus)
while zune.task.wait() do
	if cpu.jammed then
		print("\ncpu jammed")
		break
	end
	mos6502.cpu.step(cpu, bus)
end
