local luau6502 = {}

local mos6502 = require("@self/mos6502")
luau6502.mos6502 = mos6502
export type Mos6502 = mos6502.Mos6502

local bus = require("@self/bus")
luau6502.bus = bus
export type Bus = bus.Bus
export type MemoryMap = bus.MemoryMap
export type MemoryRegion = bus.MemoryRegion

local Wdc65C02 = require("@self/Wdc65c02")
luau6502.Wdc65C02 = Wdc65C02
export type Wdc65c02 = Wdc65C02.Wdc65C02
export type IntoMemory = Wdc65C02.IntoMemory
export type Memory = Wdc65C02.Memory

return luau6502
