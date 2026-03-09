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

local logic = {}
logic[0x01] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 6
    local ptr = add_u8(read(PC), X)
    PC += 1
    local base_address = concat_u16(read(ptr), read(add_u8(ptr, 1)))
    local address = base_address
    
    local value = read(address)
    A = bit32.bor(value, A)
    N, Z = A, A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x04] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local base_address = read(PC)
    PC += 1
    local address = base_address
    local value = read(address)
    Z = bit32.band(A, value)
    local result = bit32.bor(A, value)
    write(address, result)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x05] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 3
    local base_address = read(PC)
    PC += 1
    local address = base_address
    local value = read(address)
    A = bit32.bor(value, A)
    N, Z = A, A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x09] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 2
    local value = read(PC)
    PC += 1
    local address = nil
    local base_address = nil
    A = bit32.bor(value, A)
    N, Z = A, A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x0C] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 6
    local lo = read(PC)
    PC += 1
    local hi = read(PC)
    PC += 1
    local base_address = concat_u16(lo, hi)
    local address = base_address
    local value = read(address)
    Z = bit32.band(A, value)
    local result = bit32.bor(A, value)
    write(address, result)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x0D] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local lo = read(PC)
    PC += 1
    local hi = read(PC)
    PC += 1
    local base_address = concat_u16(lo, hi)
    local address = base_address
    local value = read(address)
    A = bit32.bor(value, A)
    N, Z = A, A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x11] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
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
    A = bit32.bor(value, A)
    N, Z = A, A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x12] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local ptr = read(PC)
    PC += 1
    local base_address = concat_u16(read(ptr), read(add_u8(ptr, 1)))
    local address = base_address
    local value = read(address)
    A = bit32.bor(value, A)
    N, Z = A, A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x14] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local base_address = read(PC)
    PC += 1
    local address = base_address
    local value = read(address)
    Z = bit32.band(A, value)
    local result = bit32.bor(value, A)
    write(address, result)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x15] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local base_address = read(PC)
    PC += 1
    local address = add_u8(base_address, X)
    local value = read(address)
    A = bit32.bor(value, A)
    N, Z = A, A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x19] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
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
    A = bit32.bor(value, A)
    N, Z = A, A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x1C] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 6
    local lo = read(PC)
    PC += 1
    local hi = read(PC)
    PC += 1
    local base_address = concat_u16(lo, hi)
    local address = base_address
    local value = read(address)
    Z = bit32.band(A, value)
    local result = bit32.bor(value, A)
    write(address, result)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x1D] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
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
    A = bit32.bor(value, A)
    N, Z = A, A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x21] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 6
    local ptr = add_u8(read(PC), X)
    PC += 1
    local base_address = concat_u16(read(ptr), read(add_u8(ptr, 1)))
    local address = base_address
    
    local value = read(address)
    A = bit32.band(value, A)
    N, Z = A, A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x24] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 3
    local base_address = read(PC)
    PC += 1
    local address = base_address
    local value = read(address)
    local res = bit32.band(A, value)
    Z = res
    
    if address then
        V = bit32.band(value, 0x40) ~= 0
        N = value
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x25] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 3
    local base_address = read(PC)
    PC += 1
    local address = base_address
    local value = read(address)
    A = bit32.band(value, A)
    N, Z = A, A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x29] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 2
    local value = read(PC)
    PC += 1
    local address = nil
    local base_address = nil
    A = bit32.band(value, A)
    N, Z = A, A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x2C] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local lo = read(PC)
    PC += 1
    local hi = read(PC)
    PC += 1
    local base_address = concat_u16(lo, hi)
    local address = base_address
    local value = read(address)
    local res = bit32.band(A, value)
    Z = res
    
    if address then
        V = bit32.band(value, 0x40) ~= 0
        N = value
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x2D] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local lo = read(PC)
    PC += 1
    local hi = read(PC)
    PC += 1
    local base_address = concat_u16(lo, hi)
    local address = base_address
    local value = read(address)
    A = bit32.band(value, A)
    N, Z = A, A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x31] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
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
    A = bit32.band(value, A)
    N, Z = A, A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x32] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local ptr = read(PC)
    PC += 1
    local base_address = concat_u16(read(ptr), read(add_u8(ptr, 1)))
    local address = base_address
    local value = read(address)
    A = bit32.band(value, A)
    N, Z = A, A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x34] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local base_address = read(PC)
    PC += 1
    local address = add_u8(base_address, X)
    local value = read(address)
    local res = bit32.band(A, value)
    Z = res
    
    if address then
        V = bit32.band(value, 0x40) ~= 0
        N = value
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x35] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local base_address = read(PC)
    PC += 1
    local address = add_u8(base_address, X)
    local value = read(address)
    A = bit32.band(value, A)
    N, Z = A, A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x39] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
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
    A = bit32.band(value, A)
    N, Z = A, A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x3C] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
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
    local res = bit32.band(A, value)
    Z = res
    
    if address then
        V = bit32.band(value, 0x40) ~= 0
        N = value
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x3D] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
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
    A = bit32.band(value, A)
    N, Z = A, A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x41] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 6
    local ptr = add_u8(read(PC), X)
    PC += 1
    local base_address = concat_u16(read(ptr), read(add_u8(ptr, 1)))
    local address = base_address
    
    local value = read(address)
    A = bit32.bxor(value, A)
    N, Z = A, A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x45] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 3
    local base_address = read(PC)
    PC += 1
    local address = base_address
    local value = read(address)
    A = bit32.bxor(value, A)
    N, Z = A, A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x49] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 2
    local value = read(PC)
    PC += 1
    local address = nil
    local base_address = nil
    A = bit32.bxor(value, A)
    N, Z = A, A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x4D] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local lo = read(PC)
    PC += 1
    local hi = read(PC)
    PC += 1
    local base_address = concat_u16(lo, hi)
    local address = base_address
    local value = read(address)
    A = bit32.bxor(value, A)
    N, Z = A, A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x51] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
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
    A = bit32.bxor(value, A)
    N, Z = A, A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x52] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local ptr = read(PC)
    PC += 1
    local base_address = concat_u16(read(ptr), read(add_u8(ptr, 1)))
    local address = base_address
    local value = read(address)
    A = bit32.bxor(value, A)
    N, Z = A, A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x55] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local base_address = read(PC)
    PC += 1
    local address = add_u8(base_address, X)
    local value = read(address)
    A = bit32.bxor(value, A)
    N, Z = A, A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x59] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
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
    A = bit32.bxor(value, A)
    N, Z = A, A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x5D] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
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
    A = bit32.bxor(value, A)
    N, Z = A, A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

logic[0x89] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 2
    local value = read(PC)
    PC += 1
    local address = nil
    local base_address = nil
    local res = bit32.band(A, value)
    Z = res
    
    if address then
        V = bit32.band(value, 0x40) ~= 0
        N = value
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

return logic
