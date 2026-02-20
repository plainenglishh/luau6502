local memory_bus = require("@self/memory_bus")
type MemoryBus = memory_bus.MemoryBus

export type u8 = number
export type u16 = number

--- Table representing the internal state of a CPU.
export type Mos6502 = {
	--- The accumulator.
	A: u8,
	--- The `X` register.
	X: u8,
	--- The `Y` register.
	Y: u8,
	--- The stack pointer.
	S: u8,
	--- The processor status register.
	P: u8,
	--- The program counter.
	PC: u16,
	--- The number of cycles taken.
	cycles: number,
}

--- Returns whether `base` and `addr` are in the same 256-byte page.
local function SAME_PAGE(base: u16, addr: u16): boolean
	return bit32.band(base, 0xFF00) == bit32.band(addr, 0xFF00)
end

--- Sums two u8-sized `number`s, wrapping if needed.
local function ADD_U8(a: u8, b: u8): u8
	return bit32.band(a + b, 0xFF)
end

--- Sums two u16-sized `number`s, wrapping if needed.
local function ADD_U16(a: u16, b: u16): u16
	return bit32.band(a + b, 0xFFFF)
end

local function REINTERPRET_SIGNED(byte: u8): number
	return byte < 0x80 and byte or byte - 0x100
end

local function REINTERPRET_UNSIGNED(byte: number): u8
	return bit32.band(byte, 0xFF)
end

local function U8_CONCAT(lo: u8, hi: u8): u16
	return bit32.bor(bit32.lshift(hi, 8), lo)
end

--[=[
    Fetch the next byte, incrementing the program counter.
]=]
local function fetch(cpu: Mos6502, memory: MemoryBus): u8
	local insn = memory.read(cpu.PC)
	cpu.PC = ADD_U16(cpu.PC, 1)
	return insn
end

local function fetch_u16(cpu: Mos6502, memory: MemoryBus): u16
	return U8_CONCAT(fetch(cpu, memory), fetch(cpu, memory))
end

--[=[
    Updates the NZ processor flags based on the accumulator value.
]=]
local function update_nz_flags(cpu: Mos6502)
	local p = cpu.P
	p = bit32.replace(p, cpu.A == 0 and 1 or 0, 1)
	p = bit32.replace(p, cpu.A >= 0x80 and 1 or 0, 7)
	cpu.P = p
end

--[[
--- Returns an address, and how many additional cycles the addressing took.
type AddressingMode = (cpu: CpuState, memory: Memory) -> (number, number)

local addressing_modes = {
	IMP = function(cpu: CpuState, memory: Memory): (number, number)
		return 0, 0
	end,

	ACC = function(cpu: CpuState, memory: Memory): (number, number)
		return cpu.A, 0
	end,

	IMM = function(cpu: CpuState, memory: Memory): (number, number)
		return fetch(cpu, memory), 0
	end,

	ABS = function(cpu: CpuState, memory: Memory): (number, number)
		local lo = fetch(cpu, memory)
		local hi = fetch(cpu, memory)
		local addr = bit32.bor(bit32.lshift(hi, 8), lo)
		return memory.read(addr), 0
	end,

	ABX = function(cpu: CpuState, memory: Memory): (number, number)
		local lo = fetch(cpu, memory)
		local hi = fetch(cpu, memory)
		local base = bit32.bor(bit32.lshift(hi, 8), lo)
		local addr = ADD_U16(base, cpu.X)
		return memory.read(addr), SAME_PAGE(base, addr) and 0 or 1
	end,

	ABY = function(cpu: CpuState, memory: Memory): (number, number)
		local lo = fetch(cpu, memory)
		local hi = fetch(cpu, memory)
		local base = bit32.bor(bit32.lshift(hi, 8), lo)
		local addr = ADD_U16(base, cpu.Y)
		return memory.read(addr), SAME_PAGE(base, addr) and 0 or 1
	end,

	ZP0 = function(cpu: CpuState, memory: Memory): (number, number)
		local addr = fetch(cpu, memory)
		return memory.read(addr), 0
	end,

	ZPX = function(cpu: CpuState, memory: Memory): (number, number)
		local base = fetch(cpu, memory)
		local addr = ADD_U8(base, cpu.X)
		return memory.read(addr), 0
	end,

	ZPY = function(cpu: CpuState, memory: Memory): (number, number)
		local base = fetch(cpu, memory)
		local addr = ADD_U8(base, cpu.Y)
		return memory.read(addr), 0
	end,

	IZX = function(cpu: CpuState, memory: Memory): (number, number)
		local t_addr = ADD_U8(fetch(cpu, memory), cpu.X)
		local lo = memory.read(t_addr)
		local hi = memory.read(ADD_U8(t_addr, 1))
		local addr = bit32.bor(bit32.lshift(hi, 8), lo)
		return memory.read(addr), 0
	end,

	IZY = function(cpu: CpuState, memory: Memory): (number, number)
		local t_addr = fetch(cpu, memory)
		local lo = memory.read(t_addr)
		local hi = memory.read(ADD_U8(t_addr, 1))
		local addr = bit32.bor(bit32.lshift(hi, 8), lo)
		return memory.read(ADD_U16(addr, cpu.Y)), 0
	end,

	REL = function(cpu: CpuState, memory: Memory): (number, number)
		return REINTERPRET_SIGNED(fetch(cpu, memory)), 0
	end,
}]]

type AddressingMode = "IMP" | "ACC" | "IMM" | "ABS" | "ABX" | "ABY" | "ZP0" | "ZPX" | "ZPY" | "IZX" | "IZY" | "REL"

--[=[
	Resolves a memory address from a given addressing mode. Returns whether
	the address crosses a memory page boundry, if offsetted.
]=]
local function resolve_address(cpu: Mos6502, memory: MemoryBus, mode: AddressingMode): (u16, boolean)
	if mode == "ABS" then
		local addr = fetch_u16(cpu, memory)
		return addr, false
	elseif mode == "ABX" then
		local base = fetch_u16(cpu, memory)
		local offset = cpu.X
		local addr = ADD_U16(base, offset)
		return addr, not SAME_PAGE(base, addr)
	elseif mode == "ABY" then
		local base = fetch_u16(cpu, memory)
		local offset = cpu.Y
		local addr = ADD_U16(base, offset)
		return addr, not SAME_PAGE(base, addr)
	elseif mode == "ZP0" then
		local addr = fetch(cpu, memory)
		return addr, false
	elseif mode == "ZPX" then
		local base = fetch(cpu, memory)
		local offset = cpu.X
		local addr = ADD_U8(base, offset)
		return addr, false
	elseif mode == "ZPY" then
		local base = fetch(cpu, memory)
		local offset = cpu.Y
		local addr = ADD_U8(base, offset)
		return addr, false
	elseif mode == "IZX" then
		local t_addr = ADD_U8(fetch(cpu, memory), cpu.X)
		local addr = U8_CONCAT(memory.read(t_addr), memory.read(ADD_U8(t_addr, 1)))
		return addr, false
	elseif mode == "IZY" then
		local t_addr = fetch(cpu, memory)
		local base = U8_CONCAT(memory.read(t_addr), memory.read(ADD_U8(t_addr, 1)))
		local addr = ADD_U16(base, cpu.Y)
		return addr, not SAME_PAGE(base, addr)
	else
		error(`can't resolve address for addressing mode {mode}`)
	end
end

local function resolve_value(cpu: Mos6502, memory: MemoryBus, mode: AddressingMode): (u8, boolean)
	if mode == "IMP" then
		return 0, false
	elseif mode == "ACC" then
		return cpu.A, false
	elseif mode == "IMM" then
		return fetch(cpu, memory), false
	else
		local addr, page_crossed = resolve_address(cpu, memory, mode)
		return memory.read(addr), page_crossed
	end
end

--- Returns the number of additional cycles took.
type Op = (cpu: Mos6502, memory: MemoryBus, mode: AddressingMode) -> number

local ops = {
	LDA = function(cpu: Mos6502, memory: MemoryBus, mode: AddressingMode): number
		local value, page_crossed = resolve_value(cpu, memory, mode)
		cpu.A = value
		update_nz_flags(cpu)
		return if page_crossed then 1 else 0
	end,

	STA = function(cpu: Mos6502, memory: MemoryBus, mode: AddressingMode): number
		local addr = resolve_address(cpu, memory, mode)
		memory.write(addr, cpu.A)
		return 0
	end,
}

type InstructionInfo = {
	op: Op,
	mode: AddressingMode,
	base_cycles: number,
}

local instructions: { [number]: InstructionInfo } = {
	-- LDA
	[0xA9] = { op = ops.LDA, mode = "IMM", base_cycles = 2 },
	[0xA5] = { op = ops.LDA, mode = "ZP0", base_cycles = 3 },
	[0xB5] = { op = ops.LDA, mode = "ZPX", base_cycles = 4 },
	[0xAD] = { op = ops.LDA, mode = "ABS", base_cycles = 4 },
	[0xBD] = { op = ops.LDA, mode = "ABX", base_cycles = 4 },
	[0xB9] = { op = ops.LDA, mode = "ABY", base_cycles = 4 },
	[0xA1] = { op = ops.LDA, mode = "IZX", base_cycles = 6 },
	[0xB1] = { op = ops.LDA, mode = "IZY", base_cycles = 5 },
}

local mos6502 = {}

function mos6502.create(memory: MemoryBus): Mos6502
	local cpu = {
		A = 0,
		X = 0,
		Y = 0,
		P = 0,
		S = 0,
		PC = 0,
		cycles = 0,
	}

	mos6502.reset(cpu, memory)

	return cpu
end

function mos6502.step(cpu: Mos6502, memory: MemoryBus)
	local opcode = fetch(cpu, memory)
	local insn = instructions[opcode]
	if not insn then
		error("op not implemented")
	end

	cpu.cycles += insn.base_cycles
	cpu.cycles += insn.op(cpu, memory, insn.mode)
end

function mos6502.reset(cpu: Mos6502, memory: MemoryBus)
	cpu.A = 0
	cpu.X = 0
	cpu.Y = 0
	cpu.P = 0
	cpu.S = 0xFD
	cpu.PC = U8_CONCAT(memory.read(0xFFFC), memory.read(0xFFFD))
	cpu.cycles = 0
end

return mos6502
