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

local load = {}
load[0x64] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local base_address = read(PC)
    PC += 1
    local address = base_address
    write(address, 0)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0x74] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local base_address = read(PC)
    PC += 1
    local address = add_u8(base_address, X)
    write(address, 0)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0x81] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 7
    local ptr = add_u8(read(PC), X)
    PC += 1
    local base_address = concat_u16(read(ptr), read(add_u8(ptr, 1)))
    local address = base_address
    
    write(address, A)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0x84] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local base_address = read(PC)
    PC += 1
    local address = base_address
    write(address, Y)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0x85] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local base_address = read(PC)
    PC += 1
    local address = base_address
    write(address, A)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0x86] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local base_address = read(PC)
    PC += 1
    local address = base_address
    write(address, X)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0x8C] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local lo = read(PC)
    PC += 1
    local hi = read(PC)
    PC += 1
    local base_address = concat_u16(lo, hi)
    local address = base_address
    write(address, Y)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0x8D] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local lo = read(PC)
    PC += 1
    local hi = read(PC)
    PC += 1
    local base_address = concat_u16(lo, hi)
    local address = base_address
    write(address, A)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0x8E] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local lo = read(PC)
    PC += 1
    local hi = read(PC)
    PC += 1
    local base_address = concat_u16(lo, hi)
    local address = base_address
    write(address, X)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0x91] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 7
    local ptr = read(PC)
    PC += 1
    local base_address = concat_u16(read(ptr), read(add_u8(ptr, 1)))
    local address = add_u16(base_address, Y)
    if not same_page(base_address, address) then
        cycles += 1
    end
    write(address, A)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0x92] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 6
    local ptr = read(PC)
    PC += 1
    local base_address = concat_u16(read(ptr), read(add_u8(ptr, 1)))
    local address = base_address
    write(address, A)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0x94] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local base_address = read(PC)
    PC += 1
    local address = add_u8(base_address, X)
    write(address, Y)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0x95] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local base_address = read(PC)
    PC += 1
    local address = add_u8(base_address, X)
    write(address, A)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0x96] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local base_address = read(PC)
    PC += 1
    local address = add_u8(base_address, Y)
    write(address, X)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0x99] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 6
    local lo = read(PC)
    PC += 1
    local hi = read(PC)
    PC += 1
    local base_address = concat_u16(lo, hi)
    local address = add_u16(base_address, Y)
    if not same_page(base_address, address) then
        cycles += 1
    end
    write(address, A)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0x9C] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local lo = read(PC)
    PC += 1
    local hi = read(PC)
    PC += 1
    local base_address = concat_u16(lo, hi)
    local address = base_address
    write(address, 0)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0x9D] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
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
    write(address, A)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0x9E] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
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
    write(address, 0)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0xA0] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 2
    local value = read(PC)
    PC += 1
    local address = nil
    local base_address = nil
    Y = value
    N, Z = value, value
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0xA1] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 6
    local ptr = add_u8(read(PC), X)
    PC += 1
    local base_address = concat_u16(read(ptr), read(add_u8(ptr, 1)))
    local address = base_address
    
    local value = read(address)
    A = value
    N, Z = value, value
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0xA2] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 2
    local value = read(PC)
    PC += 1
    local address = nil
    local base_address = nil
    X = value
    N, Z = value, value
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0xA4] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 3
    local base_address = read(PC)
    PC += 1
    local address = base_address
    local value = read(address)
    Y = value
    N, Z = value, value
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0xA5] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 3
    local base_address = read(PC)
    PC += 1
    local address = base_address
    local value = read(address)
    A = value
    N, Z = value, value
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0xA6] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 3
    local base_address = read(PC)
    PC += 1
    local address = base_address
    local value = read(address)
    X = value
    N, Z = value, value
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0xA9] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 2
    local value = read(PC)
    PC += 1
    local address = nil
    local base_address = nil
    A = value
    N, Z = value, value
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0xAC] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local lo = read(PC)
    PC += 1
    local hi = read(PC)
    PC += 1
    local base_address = concat_u16(lo, hi)
    local address = base_address
    local value = read(address)
    Y = value
    N, Z = value, value
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0xAD] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local lo = read(PC)
    PC += 1
    local hi = read(PC)
    PC += 1
    local base_address = concat_u16(lo, hi)
    local address = base_address
    local value = read(address)
    A = value
    N, Z = value, value
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0xAE] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local lo = read(PC)
    PC += 1
    local hi = read(PC)
    PC += 1
    local base_address = concat_u16(lo, hi)
    local address = base_address
    local value = read(address)
    X = value
    N, Z = value, value
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0xB1] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local ptr = read(PC)
    PC += 1
    local base_address = concat_u16(read(ptr), read(add_u8(ptr, 1)))
    local address = add_u16(base_address, Y)
    if not same_page(base_address, address) then
        cycles += 1
    end
    local value = read(address)
    A = value
    N, Z = value, value
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0xB2] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local ptr = read(PC)
    PC += 1
    local base_address = concat_u16(read(ptr), read(add_u8(ptr, 1)))
    local address = base_address
    local value = read(address)
    A = value
    N, Z = value, value
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0xB4] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local base_address = read(PC)
    PC += 1
    local address = add_u8(base_address, X)
    local value = read(address)
    Y = value
    N, Z = value, value
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0xB5] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local base_address = read(PC)
    PC += 1
    local address = add_u8(base_address, X)
    local value = read(address)
    A = value
    N, Z = value, value
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0xB6] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local base_address = read(PC)
    PC += 1
    local address = add_u8(base_address, Y)
    local value = read(address)
    X = value
    N, Z = value, value
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0xB9] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local lo = read(PC)
    PC += 1
    local hi = read(PC)
    PC += 1
    local base_address = concat_u16(lo, hi)
    local address = add_u16(base_address, Y)
    if not same_page(base_address, address) then
        cycles += 1
    end
    local value = read(address)
    A = value
    N, Z = value, value
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0xBC] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
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
    Y = value
    N, Z = value, value
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0xBD] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
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
    A = value
    N, Z = value, value
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

load[0xBE] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local lo = read(PC)
    PC += 1
    local hi = read(PC)
    PC += 1
    local base_address = concat_u16(lo, hi)
    local address = add_u16(base_address, Y)
    if not same_page(base_address, address) then
        cycles += 1
    end
    local value = read(address)
    X = value
    N, Z = value, value
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

return load
