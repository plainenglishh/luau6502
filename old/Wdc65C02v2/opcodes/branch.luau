local function same_page(base: number, addr: number): boolean
	return bit32.band(base, 0xFF00) == bit32.band(addr, 0xFF00)
end

local function add_u8(a: number, b: number): number
	return bit32.band(a + b, 0xFF)
end

local function sub_u8(a: number, b: number): number
	return bit32.band(a - b, 0xFF)
end

local function add_u16(a: number, b: number): number
	return bit32.band(a + b, 0xFFFF)
end

local function sub_u16(a: number, b: number): number
	return bit32.band(a - b, 0xFFFF)
end

local function reinterpret_signed(byte: number): number
	return byte < 0x80 and byte or byte - 0x100
end

local function concat_u16(lo: number, hi: number): number
	return bit32.bor(bit32.lshift(hi, 8), lo)
end

local branch = {}
branch[0x10] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 2
    local offset = reinterpret_signed(read(PC))
    PC += 1
    local base_address = PC
    local address = add_u16(base_address, offset)
    if N < 0x80 then
        cycles += if same_page(base_address, address) then 1 else 2
        PC = address
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

branch[0x30] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 2
    local offset = reinterpret_signed(read(PC))
    PC += 1
    local base_address = PC
    local address = add_u16(base_address, offset)
    if N >= 0x80 then
        cycles += if same_page(base_address, address) then 1 else 2
        PC = address
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

branch[0x50] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 2
    local offset = reinterpret_signed(read(PC))
    PC += 1
    local base_address = PC
    local address = add_u16(base_address, offset)
    if not V then
        cycles += if same_page(base_address, address) then 1 else 2
        PC = address
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

branch[0x70] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 2
    local offset = reinterpret_signed(read(PC))
    PC += 1
    local base_address = PC
    local address = add_u16(base_address, offset)
    if V then
        cycles += if same_page(base_address, address) then 1 else 2
        PC = address
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

branch[0x80] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 3
    local offset = reinterpret_signed(read(PC))
    PC += 1
    local base_address = PC
    local address = add_u16(base_address, offset)
    if not same_page(base_address, address) then
        cycles += 1
    end
    PC = address
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

branch[0x90] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 2
    local offset = reinterpret_signed(read(PC))
    PC += 1
    local base_address = PC
    local address = add_u16(base_address, offset)
    if not C then
        cycles += if same_page(base_address, address) then 1 else 2
        PC = address
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

branch[0xB0] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 2
    local offset = reinterpret_signed(read(PC))
    PC += 1
    local base_address = PC
    local address = add_u16(base_address, offset)
    if C then
        cycles += if same_page(base_address, address) then 1 else 2
        PC = address
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

branch[0xD0] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 2
    local offset = reinterpret_signed(read(PC))
    PC += 1
    local base_address = PC
    local address = add_u16(base_address, offset)
    if Z ~= 0 then
        cycles += if same_page(base_address, address) then 1 else 2
        PC = address
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

branch[0xF0] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 2
    local offset = reinterpret_signed(read(PC))
    PC += 1
    local base_address = PC
    local address = add_u16(base_address, offset)
    if Z == 0 then
        cycles += if same_page(base_address, address) then 1 else 2
        PC = address
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

return branch
