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

local shift = {}
shift[0x06] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local base_address = read(PC)
    PC += 1
    local address = base_address
    local value = read(address)
    local result = bit32.lshift(value, 1)
    C = bit32.band(result, 0x100) ~= 0
    result = bit32.band(result, 0xFF)
    write(address, result)
    N, Z = result, result
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

shift[0x0A] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 2
    local value = A
    local address = nil
    local base_address = nil
    local result = bit32.lshift(value, 1)
    C = bit32.band(result, 0x100) ~= 0
    result = bit32.band(result, 0xFF)
    A = result
    N, Z = result, result
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

shift[0x0E] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 6
    local lo = read(PC)
    PC += 1
    local hi = read(PC)
    PC += 1
    local base_address = concat_u16(lo, hi)
    local address = base_address
    local value = read(address)
    local result = bit32.lshift(value, 1)
    C = bit32.band(result, 0x100) ~= 0
    result = bit32.band(result, 0xFF)
    write(address, result)
    N, Z = result, result
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

shift[0x16] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 6
    local base_address = read(PC)
    PC += 1
    local address = add_u8(base_address, X)
    local value = read(address)
    local result = bit32.lshift(value, 1)
    C = bit32.band(result, 0x100) ~= 0
    result = bit32.band(result, 0xFF)
    write(address, result)
    N, Z = result, result
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

shift[0x1E] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 6
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
    local result = bit32.lshift(value, 1)
    C = bit32.band(result, 0x100) ~= 0
    result = bit32.band(result, 0xFF)
    write(address, result)
    N, Z = result, result
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

shift[0x26] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local base_address = read(PC)
    PC += 1
    local address = base_address
    local value = read(address)
    local result = bit32.bor(bit32.lshift(value, 1), if C then 1 else 0)
    C = bit32.band(result, 0x100) ~= 0
    result = bit32.band(result, 0xFF)
    write(address, result)
    N, Z = result, result
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

shift[0x2A] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 2
    local value = A
    local address = nil
    local base_address = nil
    local result = bit32.bor(bit32.lshift(value, 1), if C then 1 else 0)
    C = bit32.band(result, 0x100) ~= 0
    result = bit32.band(result, 0xFF)
    A = result
    N, Z = result, result
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

shift[0x2E] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 6
    local lo = read(PC)
    PC += 1
    local hi = read(PC)
    PC += 1
    local base_address = concat_u16(lo, hi)
    local address = base_address
    local value = read(address)
    local result = bit32.bor(bit32.lshift(value, 1), if C then 1 else 0)
    C = bit32.band(result, 0x100) ~= 0
    result = bit32.band(result, 0xFF)
    write(address, result)
    N, Z = result, result
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

shift[0x36] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 6
    local base_address = read(PC)
    PC += 1
    local address = add_u8(base_address, X)
    local value = read(address)
    local result = bit32.bor(bit32.lshift(value, 1), if C then 1 else 0)
    C = bit32.band(result, 0x100) ~= 0
    result = bit32.band(result, 0xFF)
    write(address, result)
    N, Z = result, result
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

shift[0x3E] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 6
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
    local result = bit32.bor(bit32.lshift(value, 1), if C then 1 else 0)
    C = bit32.band(result, 0x100) ~= 0
    result = bit32.band(result, 0xFF)
    write(address, result)
    N, Z = result, result
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

shift[0x46] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local base_address = read(PC)
    PC += 1
    local address = base_address
    local value = read(address)
    C = bit32.band(value, 0x01) ~= 0
    local result = bit32.rshift(value, 1)
    write(address, result)
    N, Z = result, result
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

shift[0x4A] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 2
    local value = A
    local address = nil
    local base_address = nil
    C = bit32.band(value, 0x01) ~= 0
    local result = bit32.rshift(value, 1)
    A = result
    N, Z = result, result
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

shift[0x4E] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 6
    local lo = read(PC)
    PC += 1
    local hi = read(PC)
    PC += 1
    local base_address = concat_u16(lo, hi)
    local address = base_address
    local value = read(address)
    C = bit32.band(value, 0x01) ~= 0
    local result = bit32.rshift(value, 1)
    write(address, result)
    N, Z = result, result
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

shift[0x56] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 6
    local base_address = read(PC)
    PC += 1
    local address = add_u8(base_address, X)
    local value = read(address)
    C = bit32.band(value, 0x01) ~= 0
    local result = bit32.rshift(value, 1)
    write(address, result)
    N, Z = result, result
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

shift[0x5E] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 6
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
    C = bit32.band(value, 0x01) ~= 0
    local result = bit32.rshift(value, 1)
    write(address, result)
    N, Z = result, result
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

shift[0x66] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local base_address = read(PC)
    PC += 1
    local address = base_address
    local value = read(address)
    local result = bit32.bor(bit32.rshift(value, 1), if C then 0x80 else 0)
    C = bit32.band(value, 0x01) ~= 0
    write(address, result)
    N, Z = result, result
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

shift[0x6A] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 2
    local value = A
    local address = nil
    local base_address = nil
    local result = bit32.bor(bit32.rshift(value, 1), if C then 0x80 else 0)
    C = bit32.band(value, 0x01) ~= 0
    A = result
    N, Z = result, result
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

shift[0x6E] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 6
    local lo = read(PC)
    PC += 1
    local hi = read(PC)
    PC += 1
    local base_address = concat_u16(lo, hi)
    local address = base_address
    local value = read(address)
    local result = bit32.bor(bit32.rshift(value, 1), if C then 0x80 else 0)
    C = bit32.band(value, 0x01) ~= 0
    write(address, result)
    N, Z = result, result
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

shift[0x76] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 6
    local base_address = read(PC)
    PC += 1
    local address = add_u8(base_address, X)
    local value = read(address)
    local result = bit32.bor(bit32.rshift(value, 1), if C then 0x80 else 0)
    C = bit32.band(value, 0x01) ~= 0
    write(address, result)
    N, Z = result, result
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

shift[0x7E] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 6
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
    local result = bit32.bor(bit32.rshift(value, 1), if C then 0x80 else 0)
    C = bit32.band(value, 0x01) ~= 0
    write(address, result)
    N, Z = result, result
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

return shift
