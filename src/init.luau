local bus = require("@self/bus")
local cpu = require("@self/cpu")

local mos6502 = {}

mos6502.cpu = cpu
mos6502.bus = bus

return mos6502
