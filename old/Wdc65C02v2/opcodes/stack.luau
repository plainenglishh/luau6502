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

local stack = {}
stack[0x08] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 3
    push(bit32.bor(get_p(true), 0x30))
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

stack[0x28] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    set_p(pull())
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

stack[0x48] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 3
    push(A)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

stack[0x5A] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 3
    push(Y)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

stack[0x68] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    A = pull()
    N, Z = A, A
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

stack[0x7A] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    Y = pull()
    N, Z = Y, Y
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

stack[0xDA] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 3
    push(X)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

stack[0xFA] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    X = pull()
    N, Z = X, X
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

return stack
