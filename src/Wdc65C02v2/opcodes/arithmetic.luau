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

local arithmetic = {}
arithmetic[0x61] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 6
    local ptr = add_u8(read(PC), X)
    PC += 1
    local base_address = concat_u16(read(ptr), read(add_u8(ptr, 1)))
    local address = base_address
    
    local value = read(address)
    if not D then
        local result = A + value + (if C then 1 else 0)
        V = bit32.band(bit32.bxor(A, result), bit32.bxor(value, result), 0x80) ~= 0
        C = result > 0xFF
        A = bit32.band(result, 0xFF)
        N, Z = A, A
    else
        cycles += 1
        local al = bit32.band(A, 0x0F)
        local ah = bit32.band(A, 0xF0)
        local vl = bit32.band(value, 0x0F)
        local vh = bit32.band(value, 0xF0)
        
        local lo = al + vl + (if C then 1 else 0)
        local hi = ah + vh
        
        if lo > 0x09 then lo += 0x06; hi += 0x10 end
        
        local binary_sum = A + value + (if C then 1 else 0)
        V = bit32.band(bit32.bxor(A, binary_sum), bit32.bxor(value, binary_sum), 0x80) ~= 0
        
        if hi > 0x90 then hi += 0x60 end
        C = hi > 0xF0
        
        A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
        N, Z = A, A
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

arithmetic[0x65] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 3
    local base_address = read(PC)
    PC += 1
    local address = base_address
    local value = read(address)
    if not D then
        local result = A + value + (if C then 1 else 0)
        V = bit32.band(bit32.bxor(A, result), bit32.bxor(value, result), 0x80) ~= 0
        C = result > 0xFF
        A = bit32.band(result, 0xFF)
        N, Z = A, A
    else
        cycles += 1
        local al = bit32.band(A, 0x0F)
        local ah = bit32.band(A, 0xF0)
        local vl = bit32.band(value, 0x0F)
        local vh = bit32.band(value, 0xF0)
        
        local lo = al + vl + (if C then 1 else 0)
        local hi = ah + vh
        
        if lo > 0x09 then lo += 0x06; hi += 0x10 end
        
        local binary_sum = A + value + (if C then 1 else 0)
        V = bit32.band(bit32.bxor(A, binary_sum), bit32.bxor(value, binary_sum), 0x80) ~= 0
        
        if hi > 0x90 then hi += 0x60 end
        C = hi > 0xF0
        
        A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
        N, Z = A, A
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

arithmetic[0x69] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 2
    local value = read(PC)
    PC += 1
    local address = nil
    local base_address = nil
    if not D then
        local result = A + value + (if C then 1 else 0)
        V = bit32.band(bit32.bxor(A, result), bit32.bxor(value, result), 0x80) ~= 0
        C = result > 0xFF
        A = bit32.band(result, 0xFF)
        N, Z = A, A
    else
        cycles += 1
        local al = bit32.band(A, 0x0F)
        local ah = bit32.band(A, 0xF0)
        local vl = bit32.band(value, 0x0F)
        local vh = bit32.band(value, 0xF0)
        
        local lo = al + vl + (if C then 1 else 0)
        local hi = ah + vh
        
        if lo > 0x09 then lo += 0x06; hi += 0x10 end
        
        local binary_sum = A + value + (if C then 1 else 0)
        V = bit32.band(bit32.bxor(A, binary_sum), bit32.bxor(value, binary_sum), 0x80) ~= 0
        
        if hi > 0x90 then hi += 0x60 end
        C = hi > 0xF0
        
        A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
        N, Z = A, A
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

arithmetic[0x6D] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local lo = read(PC)
    PC += 1
    local hi = read(PC)
    PC += 1
    local base_address = concat_u16(lo, hi)
    local address = base_address
    local value = read(address)
    if not D then
        local result = A + value + (if C then 1 else 0)
        V = bit32.band(bit32.bxor(A, result), bit32.bxor(value, result), 0x80) ~= 0
        C = result > 0xFF
        A = bit32.band(result, 0xFF)
        N, Z = A, A
    else
        cycles += 1
        local al = bit32.band(A, 0x0F)
        local ah = bit32.band(A, 0xF0)
        local vl = bit32.band(value, 0x0F)
        local vh = bit32.band(value, 0xF0)
        
        local lo = al + vl + (if C then 1 else 0)
        local hi = ah + vh
        
        if lo > 0x09 then lo += 0x06; hi += 0x10 end
        
        local binary_sum = A + value + (if C then 1 else 0)
        V = bit32.band(bit32.bxor(A, binary_sum), bit32.bxor(value, binary_sum), 0x80) ~= 0
        
        if hi > 0x90 then hi += 0x60 end
        C = hi > 0xF0
        
        A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
        N, Z = A, A
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

arithmetic[0x71] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
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
    if not D then
        local result = A + value + (if C then 1 else 0)
        V = bit32.band(bit32.bxor(A, result), bit32.bxor(value, result), 0x80) ~= 0
        C = result > 0xFF
        A = bit32.band(result, 0xFF)
        N, Z = A, A
    else
        cycles += 1
        local al = bit32.band(A, 0x0F)
        local ah = bit32.band(A, 0xF0)
        local vl = bit32.band(value, 0x0F)
        local vh = bit32.band(value, 0xF0)
        
        local lo = al + vl + (if C then 1 else 0)
        local hi = ah + vh
        
        if lo > 0x09 then lo += 0x06; hi += 0x10 end
        
        local binary_sum = A + value + (if C then 1 else 0)
        V = bit32.band(bit32.bxor(A, binary_sum), bit32.bxor(value, binary_sum), 0x80) ~= 0
        
        if hi > 0x90 then hi += 0x60 end
        C = hi > 0xF0
        
        A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
        N, Z = A, A
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

arithmetic[0x72] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local ptr = read(PC)
    PC += 1
    local base_address = concat_u16(read(ptr), read(add_u8(ptr, 1)))
    local address = base_address
    local value = read(address)
    if not D then
        local result = A + value + (if C then 1 else 0)
        V = bit32.band(bit32.bxor(A, result), bit32.bxor(value, result), 0x80) ~= 0
        C = result > 0xFF
        A = bit32.band(result, 0xFF)
        N, Z = A, A
    else
        cycles += 1
        local al = bit32.band(A, 0x0F)
        local ah = bit32.band(A, 0xF0)
        local vl = bit32.band(value, 0x0F)
        local vh = bit32.band(value, 0xF0)
        
        local lo = al + vl + (if C then 1 else 0)
        local hi = ah + vh
        
        if lo > 0x09 then lo += 0x06; hi += 0x10 end
        
        local binary_sum = A + value + (if C then 1 else 0)
        V = bit32.band(bit32.bxor(A, binary_sum), bit32.bxor(value, binary_sum), 0x80) ~= 0
        
        if hi > 0x90 then hi += 0x60 end
        C = hi > 0xF0
        
        A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
        N, Z = A, A
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

arithmetic[0x75] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local base_address = read(PC)
    PC += 1
    local address = add_u8(base_address, X)
    local value = read(address)
    if not D then
        local result = A + value + (if C then 1 else 0)
        V = bit32.band(bit32.bxor(A, result), bit32.bxor(value, result), 0x80) ~= 0
        C = result > 0xFF
        A = bit32.band(result, 0xFF)
        N, Z = A, A
    else
        cycles += 1
        local al = bit32.band(A, 0x0F)
        local ah = bit32.band(A, 0xF0)
        local vl = bit32.band(value, 0x0F)
        local vh = bit32.band(value, 0xF0)
        
        local lo = al + vl + (if C then 1 else 0)
        local hi = ah + vh
        
        if lo > 0x09 then lo += 0x06; hi += 0x10 end
        
        local binary_sum = A + value + (if C then 1 else 0)
        V = bit32.band(bit32.bxor(A, binary_sum), bit32.bxor(value, binary_sum), 0x80) ~= 0
        
        if hi > 0x90 then hi += 0x60 end
        C = hi > 0xF0
        
        A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
        N, Z = A, A
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

arithmetic[0x79] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
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
    if not D then
        local result = A + value + (if C then 1 else 0)
        V = bit32.band(bit32.bxor(A, result), bit32.bxor(value, result), 0x80) ~= 0
        C = result > 0xFF
        A = bit32.band(result, 0xFF)
        N, Z = A, A
    else
        cycles += 1
        local al = bit32.band(A, 0x0F)
        local ah = bit32.band(A, 0xF0)
        local vl = bit32.band(value, 0x0F)
        local vh = bit32.band(value, 0xF0)
        
        local lo = al + vl + (if C then 1 else 0)
        local hi = ah + vh
        
        if lo > 0x09 then lo += 0x06; hi += 0x10 end
        
        local binary_sum = A + value + (if C then 1 else 0)
        V = bit32.band(bit32.bxor(A, binary_sum), bit32.bxor(value, binary_sum), 0x80) ~= 0
        
        if hi > 0x90 then hi += 0x60 end
        C = hi > 0xF0
        
        A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
        N, Z = A, A
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

arithmetic[0x7D] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
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
    if not D then
        local result = A + value + (if C then 1 else 0)
        V = bit32.band(bit32.bxor(A, result), bit32.bxor(value, result), 0x80) ~= 0
        C = result > 0xFF
        A = bit32.band(result, 0xFF)
        N, Z = A, A
    else
        cycles += 1
        local al = bit32.band(A, 0x0F)
        local ah = bit32.band(A, 0xF0)
        local vl = bit32.band(value, 0x0F)
        local vh = bit32.band(value, 0xF0)
        
        local lo = al + vl + (if C then 1 else 0)
        local hi = ah + vh
        
        if lo > 0x09 then lo += 0x06; hi += 0x10 end
        
        local binary_sum = A + value + (if C then 1 else 0)
        V = bit32.band(bit32.bxor(A, binary_sum), bit32.bxor(value, binary_sum), 0x80) ~= 0
        
        if hi > 0x90 then hi += 0x60 end
        C = hi > 0xF0
        
        A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
        N, Z = A, A
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

arithmetic[0xC0] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 2
    local value = read(PC)
    PC += 1
    local address = nil
    local base_address = nil
    local result = sub_u8(Y, value)
    N, Z = result, result
    C = value <= Y
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

arithmetic[0xC1] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 6
    local ptr = add_u8(read(PC), X)
    PC += 1
    local base_address = concat_u16(read(ptr), read(add_u8(ptr, 1)))
    local address = base_address
    
    local value = read(address)
    local result = sub_u8(A, value)
    N, Z = result, result
    C = value <= A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

arithmetic[0xC4] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 3
    local base_address = read(PC)
    PC += 1
    local address = base_address
    local value = read(address)
    local result = sub_u8(Y, value)
    N, Z = result, result
    C = value <= Y
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

arithmetic[0xC5] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 3
    local base_address = read(PC)
    PC += 1
    local address = base_address
    local value = read(address)
    local result = sub_u8(A, value)
    N, Z = result, result
    C = value <= A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

arithmetic[0xC9] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 2
    local value = read(PC)
    PC += 1
    local address = nil
    local base_address = nil
    local result = sub_u8(A, value)
    N, Z = result, result
    C = value <= A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

arithmetic[0xCC] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local lo = read(PC)
    PC += 1
    local hi = read(PC)
    PC += 1
    local base_address = concat_u16(lo, hi)
    local address = base_address
    local value = read(address)
    local result = sub_u8(Y, value)
    N, Z = result, result
    C = value <= Y
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

arithmetic[0xCD] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local lo = read(PC)
    PC += 1
    local hi = read(PC)
    PC += 1
    local base_address = concat_u16(lo, hi)
    local address = base_address
    local value = read(address)
    local result = sub_u8(A, value)
    N, Z = result, result
    C = value <= A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

arithmetic[0xD1] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
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
    local result = sub_u8(A, value)
    N, Z = result, result
    C = value <= A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

arithmetic[0xD2] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local ptr = read(PC)
    PC += 1
    local base_address = concat_u16(read(ptr), read(add_u8(ptr, 1)))
    local address = base_address
    local value = read(address)
    local result = sub_u8(A, value)
    N, Z = result, result
    C = value <= A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

arithmetic[0xD5] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local base_address = read(PC)
    PC += 1
    local address = add_u8(base_address, X)
    local value = read(address)
    local result = sub_u8(A, value)
    N, Z = result, result
    C = value <= A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

arithmetic[0xD9] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
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
    local result = sub_u8(A, value)
    N, Z = result, result
    C = value <= A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

arithmetic[0xDD] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
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
    local result = sub_u8(A, value)
    N, Z = result, result
    C = value <= A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

arithmetic[0xE0] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 2
    local value = read(PC)
    PC += 1
    local address = nil
    local base_address = nil
    local result = sub_u8(X, value)
    N, Z = result, result
    C = value <= X
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

arithmetic[0xE1] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 6
    local ptr = add_u8(read(PC), X)
    PC += 1
    local base_address = concat_u16(read(ptr), read(add_u8(ptr, 1)))
    local address = base_address
    
    local value = read(address)
        if not D then
            local inv_value = bit32.bxor(value, 0xFF)
            local result = A + inv_value + (if C then 1 else 0)
            V = bit32.band(bit32.bxor(A, result), bit32.bxor(inv_value, result), 0x80) ~= 0
            C = result > 0xFF
            A = bit32.band(result, 0xFF)
            N, Z = A, A
        else
            cycles += 1
            local al = bit32.band(A, 0x0F)
            local ah = bit32.band(A, 0xF0)
            local vl = bit32.band(value, 0x0F)
            local vh = bit32.band(value, 0xF0)
            
            local lo = al - vl - (if C then 0 else 1)
            local hi = ah - vh
            
            if lo < 0 then lo -= 0x06; hi -= 0x10 end
            if hi < 0 then hi -= 0x60 end
            
            local binary_diff = A - value - (if C then 0 else 1)
            V = bit32.band(bit32.bxor(A, value), bit32.bxor(A, binary_diff), 0x80) ~= 0
            
            C = binary_diff >= 0
            A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
            N, Z = A, A
        end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

arithmetic[0xE4] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 3
    local base_address = read(PC)
    PC += 1
    local address = base_address
    local value = read(address)
    local result = sub_u8(X, value)
    N, Z = result, result
    C = value <= X
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

arithmetic[0xE5] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 3
    local base_address = read(PC)
    PC += 1
    local address = base_address
    local value = read(address)
        if not D then
            local inv_value = bit32.bxor(value, 0xFF)
            local result = A + inv_value + (if C then 1 else 0)
            V = bit32.band(bit32.bxor(A, result), bit32.bxor(inv_value, result), 0x80) ~= 0
            C = result > 0xFF
            A = bit32.band(result, 0xFF)
            N, Z = A, A
        else
            cycles += 1
            local al = bit32.band(A, 0x0F)
            local ah = bit32.band(A, 0xF0)
            local vl = bit32.band(value, 0x0F)
            local vh = bit32.band(value, 0xF0)
            
            local lo = al - vl - (if C then 0 else 1)
            local hi = ah - vh
            
            if lo < 0 then lo -= 0x06; hi -= 0x10 end
            if hi < 0 then hi -= 0x60 end
            
            local binary_diff = A - value - (if C then 0 else 1)
            V = bit32.band(bit32.bxor(A, value), bit32.bxor(A, binary_diff), 0x80) ~= 0
            
            C = binary_diff >= 0
            A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
            N, Z = A, A
        end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

arithmetic[0xE9] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 2
    local value = read(PC)
    PC += 1
    local address = nil
    local base_address = nil
        if not D then
            local inv_value = bit32.bxor(value, 0xFF)
            local result = A + inv_value + (if C then 1 else 0)
            V = bit32.band(bit32.bxor(A, result), bit32.bxor(inv_value, result), 0x80) ~= 0
            C = result > 0xFF
            A = bit32.band(result, 0xFF)
            N, Z = A, A
        else
            cycles += 1
            local al = bit32.band(A, 0x0F)
            local ah = bit32.band(A, 0xF0)
            local vl = bit32.band(value, 0x0F)
            local vh = bit32.band(value, 0xF0)
            
            local lo = al - vl - (if C then 0 else 1)
            local hi = ah - vh
            
            if lo < 0 then lo -= 0x06; hi -= 0x10 end
            if hi < 0 then hi -= 0x60 end
            
            local binary_diff = A - value - (if C then 0 else 1)
            V = bit32.band(bit32.bxor(A, value), bit32.bxor(A, binary_diff), 0x80) ~= 0
            
            C = binary_diff >= 0
            A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
            N, Z = A, A
        end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

arithmetic[0xEC] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local lo = read(PC)
    PC += 1
    local hi = read(PC)
    PC += 1
    local base_address = concat_u16(lo, hi)
    local address = base_address
    local value = read(address)
    local result = sub_u8(X, value)
    N, Z = result, result
    C = value <= X
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

arithmetic[0xED] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local lo = read(PC)
    PC += 1
    local hi = read(PC)
    PC += 1
    local base_address = concat_u16(lo, hi)
    local address = base_address
    local value = read(address)
        if not D then
            local inv_value = bit32.bxor(value, 0xFF)
            local result = A + inv_value + (if C then 1 else 0)
            V = bit32.band(bit32.bxor(A, result), bit32.bxor(inv_value, result), 0x80) ~= 0
            C = result > 0xFF
            A = bit32.band(result, 0xFF)
            N, Z = A, A
        else
            cycles += 1
            local al = bit32.band(A, 0x0F)
            local ah = bit32.band(A, 0xF0)
            local vl = bit32.band(value, 0x0F)
            local vh = bit32.band(value, 0xF0)
            
            local lo = al - vl - (if C then 0 else 1)
            local hi = ah - vh
            
            if lo < 0 then lo -= 0x06; hi -= 0x10 end
            if hi < 0 then hi -= 0x60 end
            
            local binary_diff = A - value - (if C then 0 else 1)
            V = bit32.band(bit32.bxor(A, value), bit32.bxor(A, binary_diff), 0x80) ~= 0
            
            C = binary_diff >= 0
            A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
            N, Z = A, A
        end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

arithmetic[0xF1] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
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
        if not D then
            local inv_value = bit32.bxor(value, 0xFF)
            local result = A + inv_value + (if C then 1 else 0)
            V = bit32.band(bit32.bxor(A, result), bit32.bxor(inv_value, result), 0x80) ~= 0
            C = result > 0xFF
            A = bit32.band(result, 0xFF)
            N, Z = A, A
        else
            cycles += 1
            local al = bit32.band(A, 0x0F)
            local ah = bit32.band(A, 0xF0)
            local vl = bit32.band(value, 0x0F)
            local vh = bit32.band(value, 0xF0)
            
            local lo = al - vl - (if C then 0 else 1)
            local hi = ah - vh
            
            if lo < 0 then lo -= 0x06; hi -= 0x10 end
            if hi < 0 then hi -= 0x60 end
            
            local binary_diff = A - value - (if C then 0 else 1)
            V = bit32.band(bit32.bxor(A, value), bit32.bxor(A, binary_diff), 0x80) ~= 0
            
            C = binary_diff >= 0
            A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
            N, Z = A, A
        end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

arithmetic[0xF2] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local ptr = read(PC)
    PC += 1
    local base_address = concat_u16(read(ptr), read(add_u8(ptr, 1)))
    local address = base_address
    local value = read(address)
        if not D then
            local inv_value = bit32.bxor(value, 0xFF)
            local result = A + inv_value + (if C then 1 else 0)
            V = bit32.band(bit32.bxor(A, result), bit32.bxor(inv_value, result), 0x80) ~= 0
            C = result > 0xFF
            A = bit32.band(result, 0xFF)
            N, Z = A, A
        else
            cycles += 1
            local al = bit32.band(A, 0x0F)
            local ah = bit32.band(A, 0xF0)
            local vl = bit32.band(value, 0x0F)
            local vh = bit32.band(value, 0xF0)
            
            local lo = al - vl - (if C then 0 else 1)
            local hi = ah - vh
            
            if lo < 0 then lo -= 0x06; hi -= 0x10 end
            if hi < 0 then hi -= 0x60 end
            
            local binary_diff = A - value - (if C then 0 else 1)
            V = bit32.band(bit32.bxor(A, value), bit32.bxor(A, binary_diff), 0x80) ~= 0
            
            C = binary_diff >= 0
            A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
            N, Z = A, A
        end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

arithmetic[0xF5] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local base_address = read(PC)
    PC += 1
    local address = add_u8(base_address, X)
    local value = read(address)
        if not D then
            local inv_value = bit32.bxor(value, 0xFF)
            local result = A + inv_value + (if C then 1 else 0)
            V = bit32.band(bit32.bxor(A, result), bit32.bxor(inv_value, result), 0x80) ~= 0
            C = result > 0xFF
            A = bit32.band(result, 0xFF)
            N, Z = A, A
        else
            cycles += 1
            local al = bit32.band(A, 0x0F)
            local ah = bit32.band(A, 0xF0)
            local vl = bit32.band(value, 0x0F)
            local vh = bit32.band(value, 0xF0)
            
            local lo = al - vl - (if C then 0 else 1)
            local hi = ah - vh
            
            if lo < 0 then lo -= 0x06; hi -= 0x10 end
            if hi < 0 then hi -= 0x60 end
            
            local binary_diff = A - value - (if C then 0 else 1)
            V = bit32.band(bit32.bxor(A, value), bit32.bxor(A, binary_diff), 0x80) ~= 0
            
            C = binary_diff >= 0
            A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
            N, Z = A, A
        end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

arithmetic[0xF9] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
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
        if not D then
            local inv_value = bit32.bxor(value, 0xFF)
            local result = A + inv_value + (if C then 1 else 0)
            V = bit32.band(bit32.bxor(A, result), bit32.bxor(inv_value, result), 0x80) ~= 0
            C = result > 0xFF
            A = bit32.band(result, 0xFF)
            N, Z = A, A
        else
            cycles += 1
            local al = bit32.band(A, 0x0F)
            local ah = bit32.band(A, 0xF0)
            local vl = bit32.band(value, 0x0F)
            local vh = bit32.band(value, 0xF0)
            
            local lo = al - vl - (if C then 0 else 1)
            local hi = ah - vh
            
            if lo < 0 then lo -= 0x06; hi -= 0x10 end
            if hi < 0 then hi -= 0x60 end
            
            local binary_diff = A - value - (if C then 0 else 1)
            V = bit32.band(bit32.bxor(A, value), bit32.bxor(A, binary_diff), 0x80) ~= 0
            
            C = binary_diff >= 0
            A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
            N, Z = A, A
        end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

arithmetic[0xFD] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
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
        if not D then
            local inv_value = bit32.bxor(value, 0xFF)
            local result = A + inv_value + (if C then 1 else 0)
            V = bit32.band(bit32.bxor(A, result), bit32.bxor(inv_value, result), 0x80) ~= 0
            C = result > 0xFF
            A = bit32.band(result, 0xFF)
            N, Z = A, A
        else
            cycles += 1
            local al = bit32.band(A, 0x0F)
            local ah = bit32.band(A, 0xF0)
            local vl = bit32.band(value, 0x0F)
            local vh = bit32.band(value, 0xF0)
            
            local lo = al - vl - (if C then 0 else 1)
            local hi = ah - vh
            
            if lo < 0 then lo -= 0x06; hi -= 0x10 end
            if hi < 0 then hi -= 0x60 end
            
            local binary_diff = A - value - (if C then 0 else 1)
            V = bit32.band(bit32.bxor(A, value), bit32.bxor(A, binary_diff), 0x80) ~= 0
            
            C = binary_diff >= 0
            A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
            N, Z = A, A
        end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

return arithmetic
