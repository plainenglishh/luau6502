local Wdc65C02 = require("./Wdc65C02")

export type MemoryBuilder = setmetatable<{}, {
	__index: getmetatable<MemoryBuilder>,
	new: () -> MemoryBuilder,
}>

local MemoryBuilder = {}
MemoryBuilder.__index = MemoryBuilder

return MemoryBuilder
