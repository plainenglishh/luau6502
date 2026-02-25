local luau6502 = require("../src")

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

local cpu = luau6502.Wdc65C02.new(memory)
while true do
	if cpu._stopped then
		break
	end
	cpu:step()
end
