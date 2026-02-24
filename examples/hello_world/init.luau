local luau6502 = require("../src")

--[[local bus = mos6502.bus.from_map({
	{
		type = "io",
		start = 0x6000,
		size = 1,
		read = function()
			return 0
		end,
		write = function(addr, value)
			zune.io.stdout:write(string.char(value))
		end,
	},
	{
		type = "buffer",
		start = 0xFF00,
		size = 256,
		mode = "rom",
		buffer = zune.fs.readFile("examples/hello_world/hello_world.bin", true),
	},
})]]

local memory: luau6502.Memory = {
	read = {
		[0xFF + 1] = zune.fs.readFile("examples/hello_world/hello_world.bin", true),
	},
	write = {
		[0x60 + 1] = function(address: number, value: number)
			if address == 0x6000 then
				zune.io.stdout:write(string.char(value))
			end
		end,
	},
}

--buffer.fill(memory.read[0] :: any, 0, 0xEA)

local cpu = luau6502.Wdc65C02.new(memory)

while true do
	if cpu._stopped then
		print("cpu stopped")
		break
	end
	cpu:step()
	--print(cpu._pc)
end
