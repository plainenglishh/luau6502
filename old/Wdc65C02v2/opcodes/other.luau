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

local other = {}
other[0x07] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local address = read(PC)
    PC += 1
    local bit_offset = 0
    local value = read(address)
    local result = bit32.replace(value, 0, bit_offset)
    write(address, result)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0x0F] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local zp_addr = read(PC)
    PC += 1
    local offset = read(PC)
    PC += 1
    local bit_offset = 0
    local rel = if offset > 127 then offset - 256 else offset
        
    local base_address = zp_addr
    local value = read(zp_addr)
    local address = add_u16(PC, rel)
    if bit32.extract(value, bit_offset) == 0 then
        cycles += if same_page(base_address, address) then 1 else 2
        PC = address
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0x17] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local address = read(PC)
    PC += 1
    local bit_offset = 1
    local value = read(address)
    local result = bit32.replace(value, 0, bit_offset)
    write(address, result)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0x1F] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local zp_addr = read(PC)
    PC += 1
    local offset = read(PC)
    PC += 1
    local bit_offset = 1
    local rel = if offset > 127 then offset - 256 else offset
        
    local base_address = zp_addr
    local value = read(zp_addr)
    local address = add_u16(PC, rel)
    if bit32.extract(value, bit_offset) == 0 then
        cycles += if same_page(base_address, address) then 1 else 2
        PC = address
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0x27] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local address = read(PC)
    PC += 1
    local bit_offset = 2
    local value = read(address)
    local result = bit32.replace(value, 0, bit_offset)
    write(address, result)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0x2F] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local zp_addr = read(PC)
    PC += 1
    local offset = read(PC)
    PC += 1
    local bit_offset = 2
    local rel = if offset > 127 then offset - 256 else offset
        
    local base_address = zp_addr
    local value = read(zp_addr)
    local address = add_u16(PC, rel)
    if bit32.extract(value, bit_offset) == 0 then
        cycles += if same_page(base_address, address) then 1 else 2
        PC = address
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0x37] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local address = read(PC)
    PC += 1
    local bit_offset = 3
    local value = read(address)
    local result = bit32.replace(value, 0, bit_offset)
    write(address, result)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0x3F] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local zp_addr = read(PC)
    PC += 1
    local offset = read(PC)
    PC += 1
    local bit_offset = 3
    local rel = if offset > 127 then offset - 256 else offset
        
    local base_address = zp_addr
    local value = read(zp_addr)
    local address = add_u16(PC, rel)
    if bit32.extract(value, bit_offset) == 0 then
        cycles += if same_page(base_address, address) then 1 else 2
        PC = address
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0x47] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local address = read(PC)
    PC += 1
    local bit_offset = 4
    local value = read(address)
    local result = bit32.replace(value, 0, bit_offset)
    write(address, result)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0x4F] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local zp_addr = read(PC)
    PC += 1
    local offset = read(PC)
    PC += 1
    local bit_offset = 4
    local rel = if offset > 127 then offset - 256 else offset
        
    local base_address = zp_addr
    local value = read(zp_addr)
    local address = add_u16(PC, rel)
    if bit32.extract(value, bit_offset) == 0 then
        cycles += if same_page(base_address, address) then 1 else 2
        PC = address
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0x57] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local address = read(PC)
    PC += 1
    local bit_offset = 5
    local value = read(address)
    local result = bit32.replace(value, 0, bit_offset)
    write(address, result)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0x5F] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local zp_addr = read(PC)
    PC += 1
    local offset = read(PC)
    PC += 1
    local bit_offset = 5
    local rel = if offset > 127 then offset - 256 else offset
        
    local base_address = zp_addr
    local value = read(zp_addr)
    local address = add_u16(PC, rel)
    if bit32.extract(value, bit_offset) == 0 then
        cycles += if same_page(base_address, address) then 1 else 2
        PC = address
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0x67] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local address = read(PC)
    PC += 1
    local bit_offset = 6
    local value = read(address)
    local result = bit32.replace(value, 0, bit_offset)
    write(address, result)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0x6F] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local zp_addr = read(PC)
    PC += 1
    local offset = read(PC)
    PC += 1
    local bit_offset = 6
    local rel = if offset > 127 then offset - 256 else offset
        
    local base_address = zp_addr
    local value = read(zp_addr)
    local address = add_u16(PC, rel)
    if bit32.extract(value, bit_offset) == 0 then
        cycles += if same_page(base_address, address) then 1 else 2
        PC = address
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0x77] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local address = read(PC)
    PC += 1
    local bit_offset = 7
    local value = read(address)
    local result = bit32.replace(value, 0, bit_offset)
    write(address, result)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0x7F] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local zp_addr = read(PC)
    PC += 1
    local offset = read(PC)
    PC += 1
    local bit_offset = 7
    local rel = if offset > 127 then offset - 256 else offset
        
    local base_address = zp_addr
    local value = read(zp_addr)
    local address = add_u16(PC, rel)
    if bit32.extract(value, bit_offset) == 0 then
        cycles += if same_page(base_address, address) then 1 else 2
        PC = address
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0x87] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local address = read(PC)
    PC += 1
    local bit_offset = 0
    local value = read(address)
    local result = bit32.replace(value, 1, bit_offset)
    write(address, result)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0x8F] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local zp_addr = read(PC)
    PC += 1
    local offset = read(PC)
    PC += 1
    local bit_offset = 0
    local rel = if offset > 127 then offset - 256 else offset
        
    local base_address = zp_addr
    local value = read(zp_addr)
    local address = add_u16(PC, rel)
    if bit32.extract(value, bit_offset) == 1 then
        cycles += if same_page(base_address, address) then 1 else 2
        PC = address
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0x97] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local address = read(PC)
    PC += 1
    local bit_offset = 1
    local value = read(address)
    local result = bit32.replace(value, 1, bit_offset)
    write(address, result)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0x9F] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local zp_addr = read(PC)
    PC += 1
    local offset = read(PC)
    PC += 1
    local bit_offset = 1
    local rel = if offset > 127 then offset - 256 else offset
        
    local base_address = zp_addr
    local value = read(zp_addr)
    local address = add_u16(PC, rel)
    if bit32.extract(value, bit_offset) == 1 then
        cycles += if same_page(base_address, address) then 1 else 2
        PC = address
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0xA7] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local address = read(PC)
    PC += 1
    local bit_offset = 2
    local value = read(address)
    local result = bit32.replace(value, 1, bit_offset)
    write(address, result)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0xAF] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local zp_addr = read(PC)
    PC += 1
    local offset = read(PC)
    PC += 1
    local bit_offset = 2
    local rel = if offset > 127 then offset - 256 else offset
        
    local base_address = zp_addr
    local value = read(zp_addr)
    local address = add_u16(PC, rel)
    if bit32.extract(value, bit_offset) == 1 then
        cycles += if same_page(base_address, address) then 1 else 2
        PC = address
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0xB7] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local address = read(PC)
    PC += 1
    local bit_offset = 3
    local value = read(address)
    local result = bit32.replace(value, 1, bit_offset)
    write(address, result)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0xBF] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local zp_addr = read(PC)
    PC += 1
    local offset = read(PC)
    PC += 1
    local bit_offset = 3
    local rel = if offset > 127 then offset - 256 else offset
        
    local base_address = zp_addr
    local value = read(zp_addr)
    local address = add_u16(PC, rel)
    if bit32.extract(value, bit_offset) == 1 then
        cycles += if same_page(base_address, address) then 1 else 2
        PC = address
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0xC7] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local address = read(PC)
    PC += 1
    local bit_offset = 4
    local value = read(address)
    local result = bit32.replace(value, 1, bit_offset)
    write(address, result)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0xCB] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    self._waiting = true
    should_break = true
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0xCF] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local zp_addr = read(PC)
    PC += 1
    local offset = read(PC)
    PC += 1
    local bit_offset = 4
    local rel = if offset > 127 then offset - 256 else offset
        
    local base_address = zp_addr
    local value = read(zp_addr)
    local address = add_u16(PC, rel)
    if bit32.extract(value, bit_offset) == 1 then
        cycles += if same_page(base_address, address) then 1 else 2
        PC = address
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0xD7] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local address = read(PC)
    PC += 1
    local bit_offset = 5
    local value = read(address)
    local result = bit32.replace(value, 1, bit_offset)
    write(address, result)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0xDB] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 2
    self._stopped = true
    should_break = true
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0xDF] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local zp_addr = read(PC)
    PC += 1
    local offset = read(PC)
    PC += 1
    local bit_offset = 5
    local rel = if offset > 127 then offset - 256 else offset
        
    local base_address = zp_addr
    local value = read(zp_addr)
    local address = add_u16(PC, rel)
    if bit32.extract(value, bit_offset) == 1 then
        cycles += if same_page(base_address, address) then 1 else 2
        PC = address
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0xE7] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local address = read(PC)
    PC += 1
    local bit_offset = 6
    local value = read(address)
    local result = bit32.replace(value, 1, bit_offset)
    write(address, result)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0xEF] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local zp_addr = read(PC)
    PC += 1
    local offset = read(PC)
    PC += 1
    local bit_offset = 6
    local rel = if offset > 127 then offset - 256 else offset
        
    local base_address = zp_addr
    local value = read(zp_addr)
    local address = add_u16(PC, rel)
    if bit32.extract(value, bit_offset) == 1 then
        cycles += if same_page(base_address, address) then 1 else 2
        PC = address
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0xF7] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 5
    local address = read(PC)
    PC += 1
    local bit_offset = 7
    local value = read(address)
    local result = bit32.replace(value, 1, bit_offset)
    write(address, result)
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

other[0xFF] = function(self: any, read: (number) -> number, write: (number, number) -> (), A: number, X: number, Y: number, S: number, PC: number, N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean, cycles: number): (number, number, number, number, number, number, number, boolean, boolean, boolean, boolean, number, boolean)
    local should_break = false
    cycles += 4
    local zp_addr = read(PC)
    PC += 1
    local offset = read(PC)
    PC += 1
    local bit_offset = 7
    local rel = if offset > 127 then offset - 256 else offset
        
    local base_address = zp_addr
    local value = read(zp_addr)
    local address = add_u16(PC, rel)
    if bit32.extract(value, bit_offset) == 1 then
        cycles += if same_page(base_address, address) then 1 else 2
        PC = address
    end
    
    return A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break
end

return other
