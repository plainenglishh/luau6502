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

local increment = {}
increment[0x1A] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 2
    local value = A
    local address = nil
    local base_address = nil
    local result = add_u8(value, 1)
    N, Z = result, result
    A = result
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

increment[0x3A] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 2
    local value = A
    local address = nil
    local base_address = nil
    local result = sub_u8(value, 1)
    N, Z = result, result
    A = result
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

increment[0x88] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 2
    Y = sub_u8(Y, 1)
    N, Z = Y, Y
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

increment[0xC6] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local base_address = read(PC)
    PC += 1
    local address = base_address
    local value = read(address)
    local result = sub_u8(value, 1)
    N, Z = result, result
    write(address, result)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

increment[0xC8] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 2
    Y = add_u8(Y, 1)
    N, Z = Y, Y
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

increment[0xCA] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 2
    X = sub_u8(X, 1)
    N, Z = X, X
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

increment[0xCE] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 6
    local lo = read(PC)
    PC += 1
    local hi = read(PC)
    PC += 1
    local base_address = concat_u16(lo, hi)
    local address = base_address
    local value = read(address)
    local result = sub_u8(value, 1)
    N, Z = result, result
    write(address, result)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

increment[0xD6] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 6
    local base_address = read(PC)
    PC += 1
    local address = add_u8(base_address, X)
    local value = read(address)
    local result = sub_u8(value, 1)
    N, Z = result, result
    write(address, result)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

increment[0xDE] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 7
    local lo = read(PC)
    PC += 1
    local hi = read(PC)
    PC += 1
    local base_address = concat_u16(lo, hi)
    local address = add_u16(base_address, X)
    if not same_page(base_address, address) then
        cycles += 1
    end
    local value = read(address)
    local result = sub_u8(value, 1)
    N, Z = result, result
    write(address, result)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

increment[0xE6] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local base_address = read(PC)
    PC += 1
    local address = base_address
    local value = read(address)
    local result = add_u8(value, 1)
    N, Z = result, result
    write(address, result)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

increment[0xE8] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 2
    X = add_u8(X, 1)
    N, Z = X, X
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

increment[0xEE] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 6
    local lo = read(PC)
    PC += 1
    local hi = read(PC)
    PC += 1
    local base_address = concat_u16(lo, hi)
    local address = base_address
    local value = read(address)
    local result = add_u8(value, 1)
    N, Z = result, result
    write(address, result)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

increment[0xF6] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 6
    local base_address = read(PC)
    PC += 1
    local address = add_u8(base_address, X)
    local value = read(address)
    local result = add_u8(value, 1)
    N, Z = result, result
    write(address, result)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

increment[0xFE] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 7
    local lo = read(PC)
    PC += 1
    local hi = read(PC)
    PC += 1
    local base_address = concat_u16(lo, hi)
    local address = add_u16(base_address, X)
    if not same_page(base_address, address) then
        cycles += 1
    end
    local value = read(address)
    local result = add_u8(value, 1)
    N, Z = result, result
    write(address, result)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

return increment
