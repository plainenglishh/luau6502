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

local control = {}
control[0x20] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 6
    local lo = read(PC)
    PC += 1
    local hi = read(PC)
    PC += 1
    local base_address = concat_u16(lo, hi)
    local address = base_address
    local return_address = sub_u16(PC, 1)
    push(bit32.rshift(return_address, 8))
    push(bit32.band(return_address, 0xFF))
    PC = address
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

control[0x40] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 6
    set_p(pull())
    PC = concat_u16(pull(), pull())
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

control[0x4C] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 3
    local lo = read(PC)
    PC += 1
    local hi = read(PC)
    PC += 1
    local base_address = concat_u16(lo, hi)
    local address = base_address
    PC = address
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

control[0x60] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 6
    PC = add_u16(concat_u16(pull(), pull()), 1)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

control[0x6C] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 6
    local lo = read(PC)
    PC += 1
    local hi = read(PC)
    PC += 1
    local ptr = concat_u16(lo, hi)
    local base_address = concat_u16(read(ptr), read(add_u16(ptr, 1)))
    local address = base_address
    PC = address
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

control[0x7C] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
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
    PC = address
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

control[0x00] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 7
    if self._irq and not I then
        continue
    end
    
    handle_interrupt(0xFFFE, true)
    cycles -= 7
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

return control
