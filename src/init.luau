local mos6502 = {}

local cpu = require("@self/cpu")
mos6502.cpu = cpu
export type Cpu = cpu.Cpu

local bus = require("@self/bus")
mos6502.bus = bus
export type Bus = bus.Bus
export type MemoryMap = bus.MemoryMap
export type MemoryRegion = bus.MemoryRegion

return mos6502
