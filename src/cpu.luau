local bus = require("./bus")
type Bus = bus.Bus

local FLAG_N, FLAG_V, FLAG_U, FLAG_B, FLAG_D, FLAG_I, FLAG_Z, FLAG_C = 7, 6, 5, 4, 3, 2, 1, 0

type u8 = number
type u16 = number

--- Table representing the internal state of a CPU.
export type Cpu = {
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
	--- Whether the CPU is jammed.
	jammed: boolean,
	--- Whether a reset is pending.
	pending_reset: boolean,
	--- Whether an NMI is pending.
	pending_nmi: boolean,
	--- Whether an IRQ is pending.
	pending_irq: boolean,
}

--- Returns whether `base` and `addr` are in the same 256-byte page.
local function SAME_PAGE(base: u16, addr: u16): boolean
	return bit32.band(base, 0xFF00) == bit32.band(addr, 0xFF00)
end

--- Sums two u8-sized `number`s, wrapping if needed.
local function ADD_U8(a: u8, b: u8): u8
	return bit32.band(a + b, 0xFF)
end

--- Subtracts two u8-sized `number`s, wrapping if needed.
local function SUB_U8(a: u8, b: u8): u8
	return bit32.band(a - b, 0xFF)
end

--- Sums two u16-sized `number`s, wrapping if needed.
local function ADD_U16(a: u16, b: u16): u16
	return bit32.band(a + b, 0xFFFF)
end

--- Subtracts two u16-sized `number`s, wrapping if needed.
local function SUB_U16(a: u16, b: u16): u16
	return bit32.band(a - b, 0xFFFF)
end

local function REINTERPRET_SIGNED(byte: u8): number
	return byte < 0x80 and byte or byte - 0x100
end

local function CONCAT_U16(lo: u8, hi: u8): u16
	return bit32.bor(bit32.lshift(hi, 8), lo)
end

--[=[
    Fetch the next byte, incrementing the program counter.
]=]
local function fetch(cpu: Cpu, memory: Bus): u8
	local insn = memory.read(cpu.PC)
	cpu.PC = ADD_U16(cpu.PC, 1)
	return insn
end

local function fetch_u16(cpu: Cpu, memory: Bus): u16
	return CONCAT_U16(fetch(cpu, memory), fetch(cpu, memory))
end

local function GET_FLAG(p: number, flag: number): boolean
	return bit32.extract(p, flag) == 1
end

local function SET_FLAG(p: number, flag: number, value: boolean)
	return bit32.replace(p, if value then 1 else 0, flag)
end

--[=[
    Updates the NZ processor flags based on the accumulator value.
]=]
local function update_nz_flags(cpu: Cpu, based_on: number)
	local p = cpu.P
	p = bit32.replace(p, based_on >= 0x80 and 1 or 0, FLAG_N)
	p = bit32.replace(p, based_on == 0 and 1 or 0, FLAG_Z)
	cpu.P = p
end

type AddressingMode = "IMP" | "ACC" | "IMM" | "ABS" | "ABX" | "ABY" | "IND" | "ZP0" | "ZPX" | "ZPY" | "IZX" | "IZY" | "REL"

--[=[
	Resolves a memory address from a given addressing mode. Returns whether
	the address crosses a memory page boundry, if offsetted.

	-1 indicates the accumulator.
]=]
local function resolve_address(cpu: Cpu, memory: Bus, mode: AddressingMode): (u16, boolean)
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
	elseif mode == "IND" then
		local t_addr = fetch_u16(cpu, memory)
		local lo = memory.read(t_addr)
		local hi = memory.read(bit32.band(t_addr + 1, 0xFF00) + bit32.band(t_addr + 1, 0x00FF))
		local addr = CONCAT_U16(lo, hi)
		return addr, false
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
		local addr = CONCAT_U16(memory.read(t_addr), memory.read(ADD_U8(t_addr, 1)))
		return addr, false
	elseif mode == "IZY" then
		local t_addr = fetch(cpu, memory)
		local base = CONCAT_U16(memory.read(t_addr), memory.read(ADD_U8(t_addr, 1)))
		local addr = ADD_U16(base, cpu.Y)
		return addr, not SAME_PAGE(base, addr)
	elseif mode == "REL" then
		local offset = REINTERPRET_SIGNED(fetch(cpu, memory))
		local base = cpu.PC
		local target = ADD_U16(base, offset)
		return target, not SAME_PAGE(base, target)
	elseif mode == "ACC" then
		return -1, false
	else
		error(`can't resolve address for addressing mode {mode}`)
	end
end

--- An address of -1 maps to the accumulator.
local function store_value(cpu: Cpu, memory: Bus, addr: number, value: number)
	if addr == -1 then
		cpu.A = value
		return
	end

	memory.write(addr, value)
end

--[=[
	Loads a value from memory, a register, or an operand.

	Similar to `store_value`, an address of -1 maps to the accumulator.
]=]
local function load_value(cpu: Cpu, memory: Bus, mode_or_addr: AddressingMode | u16): (u8, boolean)
	if mode_or_addr == "IMP" then
		return 0, false
	elseif mode_or_addr == "ACC" then
		return cpu.A, false
	elseif mode_or_addr == "IMM" then
		return fetch(cpu, memory), false
	else
		local addr, page_crossed
		if type(mode_or_addr) == "number" then
			addr, page_crossed = mode_or_addr, false
		else
			addr, page_crossed = resolve_address(cpu, memory, mode_or_addr)
		end

		if addr == -1 then
			return cpu.A, false
		end

		return memory.read(addr), page_crossed
	end
end

--- Pushes a value onto the stack.
local function push_value(cpu: Cpu, memory: Bus, value: u8)
	memory.write(0x0100 + cpu.S, value)
	cpu.S = SUB_U8(cpu.S, 1)
end

--- Pops a value from the stack.
local function pull_value(cpu: Cpu, memory: Bus): u8
	cpu.S = ADD_U8(cpu.S, 1)
	return memory.read(0x0100 + cpu.S)
end

--- Increments the cycle counter by `count`, and calls the cycle hook `count` times.
local function cycle(cpu: Cpu, count: number)
	cpu.cycles += count
	--- call hook
end

local function handle_reset(cpu: Cpu, memory: Bus)
	cpu.A = 0
	cpu.X = 0
	cpu.Y = 0
	cpu.P = 0x24
	cpu.S = 0xFD
	cpu.PC = CONCAT_U16(memory.read(0xFFFC), memory.read(0xFFFD))
	cpu.cycles = 0
	cpu.jammed = false
	cpu.pending_irq = false
	cpu.pending_nmi = false
	cpu.pending_reset = false
end

local function handle_interrupt(cpu: Cpu, memory: Bus, vector: u16, brk: boolean?)
	push_value(cpu, memory, bit32.rshift(cpu.PC, 8))
	push_value(cpu, memory, bit32.band(cpu.PC, 0xFF))

	local p = cpu.P
	p = SET_FLAG(p, FLAG_B, brk or false)
	p = SET_FLAG(p, FLAG_I, true)
	push_value(cpu, memory, p)

	cpu.P = SET_FLAG(cpu.P, FLAG_I, true)
	cpu.PC = CONCAT_U16(memory.read(vector), memory.read(vector + 1))

	cycle(cpu, 7)
end

--- Returns the number of additional cycles took.
type Operation = (cpu: Cpu, memory: Bus, mode: AddressingMode) -> number

--- Helper for branch instructions
local function branch_if(cpu: Cpu, memory: Bus, flag: number, set: boolean)
	local offset = REINTERPRET_SIGNED(fetch(cpu, memory))
	local target = ADD_U16(cpu.PC, offset)
	local extra_cycles = 0
	if GET_FLAG(cpu.P, flag) == set then
		local page_crossed = bit32.band(cpu.PC, 0xFF00) ~= bit32.band(target, 0xFF00)
		cpu.PC = target
		extra_cycles = 1
		if page_crossed then
			extra_cycles = extra_cycles + 1
		end
	end
	return extra_cycles
end

local ops = {
	--[[ Load ]]
	--
	LDA = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		local value, page_crossed = load_value(cpu, memory, mode)
		cpu.A = value
		update_nz_flags(cpu, value)
		return if page_crossed then 1 else 0
	end,

	LDX = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		local value, page_crossed = load_value(cpu, memory, mode)
		cpu.X = value
		update_nz_flags(cpu, value)
		return if page_crossed then 1 else 0
	end,

	LDY = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		local value, page_crossed = load_value(cpu, memory, mode)
		cpu.Y = value
		update_nz_flags(cpu, value)
		return if page_crossed then 1 else 0
	end,

	STA = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		local addr = resolve_address(cpu, memory, mode)
		memory.write(addr, cpu.A)
		return 0
	end,

	STX = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		local addr = resolve_address(cpu, memory, mode)
		memory.write(addr, cpu.X)
		return 0
	end,

	STY = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		local addr = resolve_address(cpu, memory, mode)
		memory.write(addr, cpu.Y)
		return 0
	end,

	--[[ Trans ]]
	--
	TAX = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		cpu.X = cpu.A
		update_nz_flags(cpu, cpu.X)
		return 0
	end,

	TAY = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		cpu.Y = cpu.A
		update_nz_flags(cpu, cpu.Y)
		return 0
	end,

	TSX = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		cpu.X = cpu.S
		update_nz_flags(cpu, cpu.X)
		return 0
	end,

	TXA = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		cpu.A = cpu.X
		update_nz_flags(cpu, cpu.A)
		return 0
	end,

	TXS = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		cpu.S = cpu.X
		return 0
	end,

	TYA = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		cpu.A = cpu.Y
		update_nz_flags(cpu, cpu.A)
		return 0
	end,

	--[[ Stack ]]
	--
	PHA = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		push_value(cpu, memory, cpu.A)
		return 0
	end,

	PHP = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		push_value(cpu, memory, cpu.P)
		return 0
	end,

	PLA = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		cpu.A = pull_value(cpu, memory)
		update_nz_flags(cpu, cpu.A)
		return 0
	end,

	PLP = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		cpu.P = pull_value(cpu, memory)
		return 0
	end,

	--[[ Shift ]]
	ASL = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		local addr = resolve_address(cpu, memory, mode)
		local value = load_value(cpu, memory, addr)

		local result = bit32.band(bit32.lshift(value, 1), 0xFF)
		store_value(cpu, memory, addr, result)
		cpu.P = SET_FLAG(cpu.P, FLAG_C, bit32.rshift(value, 7) == 1)
		update_nz_flags(cpu, result)

		return 0
	end,

	LSR = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		local addr = resolve_address(cpu, memory, mode)
		local value = load_value(cpu, memory, addr)

		local result = bit32.band(bit32.rshift(value, 1), 0xFF)
		cpu.P = SET_FLAG(cpu.P, FLAG_C, bit32.band(value, 0x01) == 1)
		update_nz_flags(cpu, result)
		store_value(cpu, memory, addr, result)

		return 0
	end,

	ROL = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		local addr = resolve_address(cpu, memory, mode)
		local value = load_value(cpu, memory, addr)

		local carry_in = GET_FLAG(cpu.P, FLAG_C) and 1 or 0
		local result = bit32.band(bit32.lshift(value, 1) + carry_in, 0xFF)
		cpu.P = SET_FLAG(cpu.P, FLAG_C, bit32.rshift(value, 7) == 1)
		update_nz_flags(cpu, result)
		store_value(cpu, memory, addr, result)

		return 0
	end,

	ROR = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		local addr = resolve_address(cpu, memory, mode)
		local value = load_value(cpu, memory, addr)

		local carry_in = GET_FLAG(cpu.P, FLAG_C) and 0x80 or 0
		local result = bit32.rshift(value, 1) + carry_in
		cpu.P = SET_FLAG(cpu.P, FLAG_C, bit32.band(value, 0x01) == 1)
		update_nz_flags(cpu, result)
		store_value(cpu, memory, addr, result)

		return 0
	end,

	--[[ Logic ]]
	AND = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		local value = load_value(cpu, memory, mode)
		cpu.A = bit32.band(value, cpu.A)
		update_nz_flags(cpu, cpu.A)
		return 0
	end,

	BIT = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		local value = load_value(cpu, memory, mode)
		cpu.P = SET_FLAG(cpu.P, FLAG_Z, bit32.band(cpu.A, value) == 0)
		cpu.P = SET_FLAG(cpu.P, FLAG_N, bit32.extract(value, 7) == 1)
		cpu.P = SET_FLAG(cpu.P, FLAG_V, bit32.extract(value, 6) == 1)
		return 0
	end,

	EOR = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		local value = load_value(cpu, memory, mode)
		cpu.A = bit32.bxor(value, cpu.A)
		update_nz_flags(cpu, cpu.A)
		return 0
	end,

	ORA = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		local value = load_value(cpu, memory, mode)
		cpu.A = bit32.bor(value, cpu.A)
		update_nz_flags(cpu, cpu.A)
		return 0
	end,

	--[[ Arith ]]
	ADC = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		local value = load_value(cpu, memory, mode)
		local carry_in = GET_FLAG(cpu.P, FLAG_C) and 1 or 0

		local a = cpu.A
		local sum = a + value + carry_in
		local result = bit32.band(sum, 0xFF)

		local axv = bit32.bxor(a, value)
		local axr = bit32.bxor(a, result)
		local overflow = bit32.band(bit32.band(bit32.bnot(axv), axr), 0x80) ~= 0
		cpu.P = SET_FLAG(cpu.P, FLAG_V, overflow)

		if GET_FLAG(cpu.P, FLAG_D) then
			local lo = bit32.band(a, 0x0F) + bit32.band(value, 0x0F) + carry_in
			local hi = bit32.band(a, 0xF0) + bit32.band(value, 0xF0)

			if lo > 9 then
				lo = lo + 6
			end

			if lo > 0x0F then
				hi = hi + 0x10
			end

			if bit32.band(hi, 0x1F0) > 0x90 then
				hi = hi + 0x60
			end

			cpu.P = SET_FLAG(cpu.P, FLAG_C, hi > 0xFF)
			result = bit32.bor(bit32.band(lo, 0x0F), bit32.band(hi, 0xF0))
		else
			cpu.P = SET_FLAG(cpu.P, FLAG_C, sum > 0xFF)
		end

		cpu.A = bit32.band(result, 0xFF)
		update_nz_flags(cpu, cpu.A)

		return 0
	end,

	CMP = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		local value = load_value(cpu, memory, mode)

		local result = SUB_U8(cpu.A, value)
		cpu.P = SET_FLAG(cpu.P, FLAG_C, cpu.A >= value)
		update_nz_flags(cpu, result)

		return 0
	end,

	CPX = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		local value = load_value(cpu, memory, mode)

		local result = bit32.band(cpu.X - value, 0xFF)
		cpu.P = SET_FLAG(cpu.P, FLAG_C, cpu.X >= value)
		update_nz_flags(cpu, result)

		return 0
	end,

	CPY = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		local value = load_value(cpu, memory, mode)

		local result = bit32.band(cpu.Y - value, 0xFF)
		cpu.P = SET_FLAG(cpu.P, FLAG_C, cpu.Y >= value)
		update_nz_flags(cpu, result)

		return 0
	end,

	SBC = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		local value = load_value(cpu, memory, mode)
		local carry_in = GET_FLAG(cpu.P, FLAG_C) and 1 or 0

		local inv = bit32.band(bit32.bnot(value), 0xFF)

		local sum = cpu.A + inv + carry_in
		local result = bit32.band(sum, 0xFF)

		local overflow = bit32.band(bit32.band(bit32.bxor(cpu.A, result), bit32.bxor(cpu.A, inv)), 0x80) ~= 0
		cpu.P = SET_FLAG(cpu.P, FLAG_V, overflow)

		if GET_FLAG(cpu.P, FLAG_D) then
			local al = bit32.band(cpu.A, 0x0F) + bit32.band(inv, 0x0F) + carry_in
			local ah = bit32.rshift(cpu.A, 4) + bit32.rshift(inv, 4)

			if al > 0x09 then
				al = al + 0x06
				ah = ah + 1
			end

			if ah > 0x09 then
				ah = ah + 0x06
			end

			result = bit32.band(bit32.bor(bit32.lshift(ah, 4), bit32.band(al, 0x0F)), 0xFF)
			cpu.P = SET_FLAG(cpu.P, FLAG_C, sum > 0xFF)
		else
			cpu.P = SET_FLAG(cpu.P, FLAG_C, sum > 0xFF)
		end

		cpu.A = result
		update_nz_flags(cpu, cpu.A)

		return 0
	end,

	--[[ Inc ]]
	DEC = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		local addr = resolve_address(cpu, memory, mode)
		local result = SUB_U8(load_value(cpu, memory, addr), 1)
		update_nz_flags(cpu, result)
		store_value(cpu, memory, addr, result)
		return 0
	end,

	DEX = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		cpu.X = SUB_U8(cpu.X, 1)
		update_nz_flags(cpu, cpu.X)
		return 0
	end,

	DEY = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		cpu.Y = SUB_U8(cpu.Y, 1)
		update_nz_flags(cpu, cpu.Y)
		return 0
	end,

	INC = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		local addr = resolve_address(cpu, memory, mode)
		local result = ADD_U8(load_value(cpu, memory, addr), 1)
		update_nz_flags(cpu, result)
		store_value(cpu, memory, addr, result)
		return 0
	end,

	INX = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		cpu.X = ADD_U8(cpu.X, 1)
		update_nz_flags(cpu, cpu.X)
		return 0
	end,

	INY = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		cpu.Y = ADD_U8(cpu.Y, 1)
		update_nz_flags(cpu, cpu.Y)
		return 0
	end,

	--[[ Ctrl ]]
	BRK = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		if cpu.pending_irq and not GET_FLAG(cpu.P, FLAG_I) then
			return -7 -- Doesn't run!
		end

		handle_interrupt(cpu, memory, 0xFFFE, true)
		return -7 -- Horrible! but `handle_interrupt` cycles for us!
	end,

	JMP = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		--- special handling because of IND wrap bug
		if mode == "ABS" then
			cpu.PC = fetch_u16(cpu, memory)
		elseif mode == "IND" then
			local ptr = fetch_u16(cpu, memory)
			local lo = memory.read(ptr)
			local hi = memory.read(bit32.band(ptr + 1, 0xFF) + bit32.band(ptr, 0xFF00)) -- NMOS bug
			cpu.PC = CONCAT_U16(lo, hi)
		else
			error("JMP: unsupported addressing mode")
		end
		return 0
	end,

	JSR = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		local addr = fetch_u16(cpu, memory)

		local ret = SUB_U16(cpu.PC, 1)
		push_value(cpu, memory, bit32.rshift(ret, 8))
		push_value(cpu, memory, bit32.band(ret, 0xFF))

		cpu.PC = addr
		return 0
	end,

	RTI = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		cpu.P = SET_FLAG(pull_value(cpu, memory), FLAG_U, true)
		cpu.PC = CONCAT_U16(pull_value(cpu, memory), pull_value(cpu, memory))
		return 0
	end,

	RTS = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		cpu.PC = ADD_U16(CONCAT_U16(pull_value(cpu, memory), pull_value(cpu, memory)), 1)
		return 0
	end,

	--[[ Branch ]]
	BCC = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		return branch_if(cpu, memory, FLAG_C, false)
	end,

	BCS = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		return branch_if(cpu, memory, FLAG_C, true)
	end,

	BEQ = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		return branch_if(cpu, memory, FLAG_Z, true)
	end,

	BMI = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		return branch_if(cpu, memory, FLAG_N, true)
	end,

	BNE = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		return branch_if(cpu, memory, FLAG_Z, false)
	end,

	BPL = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		return branch_if(cpu, memory, FLAG_N, false)
	end,

	BVC = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		return branch_if(cpu, memory, FLAG_V, false)
	end,

	BVS = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		return branch_if(cpu, memory, FLAG_V, true)
	end,

	--[[ Flags ]]
	--
	CLC = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		cpu.P = SET_FLAG(cpu.P, FLAG_C, false)
		return 0
	end,

	CLD = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		cpu.P = SET_FLAG(cpu.P, FLAG_D, false)
		return 0
	end,

	CLI = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		cpu.P = SET_FLAG(cpu.P, FLAG_I, false)
		return 0
	end,

	CLV = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		cpu.P = SET_FLAG(cpu.P, FLAG_V, false)
		return 0
	end,

	SEC = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		cpu.P = SET_FLAG(cpu.P, FLAG_C, true)
		return 0
	end,

	SED = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		cpu.P = SET_FLAG(cpu.P, FLAG_D, true)
		return 0
	end,

	SEI = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		cpu.P = SET_FLAG(cpu.P, FLAG_I, true)
		return 0
	end,

	--[[ Kill ]]
	--
	JAM = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		cpu.jammed = true
		return 0
	end,

	--[[ Nop ]]
	--
	NOP = function(cpu: Cpu, memory: Bus, mode: AddressingMode): number
		return 0
	end,
}

type InstructionInfo = {
	opcode: number,
	mnemonic: string,
	operation: Operation,
	mode: AddressingMode,
	cycles: number,
	illegal: boolean,
}

local instructions: { [number]: InstructionInfo } = {
	-- CPY
	[0xC0] = { opcode = 0xC0, mnemonic = "CPY", operation = ops.CPY, mode = "IMM", cycles = 2, illegal = false },
	[0xC4] = { opcode = 0xC4, mnemonic = "CPY", operation = ops.CPY, mode = "ZP0", cycles = 3, illegal = false },
	[0xCC] = { opcode = 0xCC, mnemonic = "CPY", operation = ops.CPY, mode = "ABS", cycles = 4, illegal = false },

	-- LDA
	[0xA1] = { opcode = 0xA1, mnemonic = "LDA", operation = ops.LDA, mode = "IZX", cycles = 6, illegal = false },
	[0xA5] = { opcode = 0xA5, mnemonic = "LDA", operation = ops.LDA, mode = "ZP0", cycles = 3, illegal = false },
	[0xA9] = { opcode = 0xA9, mnemonic = "LDA", operation = ops.LDA, mode = "IMM", cycles = 2, illegal = false },
	[0xAD] = { opcode = 0xAD, mnemonic = "LDA", operation = ops.LDA, mode = "ABS", cycles = 4, illegal = false },
	[0xB1] = { opcode = 0xB1, mnemonic = "LDA", operation = ops.LDA, mode = "IZY", cycles = 5, illegal = false },
	[0xB5] = { opcode = 0xB5, mnemonic = "LDA", operation = ops.LDA, mode = "ZPX", cycles = 4, illegal = false },
	[0xB9] = { opcode = 0xB9, mnemonic = "LDA", operation = ops.LDA, mode = "ABY", cycles = 4, illegal = false },
	[0xBD] = { opcode = 0xBD, mnemonic = "LDA", operation = ops.LDA, mode = "ABX", cycles = 4, illegal = false },

	-- CLV
	[0xB8] = { opcode = 0xB8, mnemonic = "CLV", operation = ops.CLV, mode = "IMP", cycles = 2, illegal = false },

	-- ARR
	--[0x6B] = { opcode = 0x6B, mnemonic = "ARR", operation = ops.ARR, mode = "IMM", cycles = 2, illegal = true },

	-- STA
	[0x81] = { opcode = 0x81, mnemonic = "STA", operation = ops.STA, mode = "IZX", cycles = 6, illegal = false },
	[0x85] = { opcode = 0x85, mnemonic = "STA", operation = ops.STA, mode = "ZP0", cycles = 3, illegal = false },
	[0x8D] = { opcode = 0x8D, mnemonic = "STA", operation = ops.STA, mode = "ABS", cycles = 4, illegal = false },
	[0x91] = { opcode = 0x91, mnemonic = "STA", operation = ops.STA, mode = "IZY", cycles = 6, illegal = false },
	[0x95] = { opcode = 0x95, mnemonic = "STA", operation = ops.STA, mode = "ZPX", cycles = 4, illegal = false },
	[0x99] = { opcode = 0x99, mnemonic = "STA", operation = ops.STA, mode = "ABY", cycles = 5, illegal = false },
	[0x9D] = { opcode = 0x9D, mnemonic = "STA", operation = ops.STA, mode = "ABX", cycles = 5, illegal = false },

	-- SHA
	--[0x93] = { opcode = 0x93, mnemonic = "SHA", operation = ops.SHA, mode = "IZY", cycles = 6, illegal = true },
	--[0x9F] = { opcode = 0x9F, mnemonic = "SHA", operation = ops.SHA, mode = "ABY", cycles = 5, illegal = true },

	-- LDY
	[0xA0] = { opcode = 0xA0, mnemonic = "LDY", operation = ops.LDY, mode = "IMM", cycles = 2, illegal = false },
	[0xA4] = { opcode = 0xA4, mnemonic = "LDY", operation = ops.LDY, mode = "ZP0", cycles = 3, illegal = false },
	[0xAC] = { opcode = 0xAC, mnemonic = "LDY", operation = ops.LDY, mode = "ABS", cycles = 4, illegal = false },
	[0xB4] = { opcode = 0xB4, mnemonic = "LDY", operation = ops.LDY, mode = "ZPX", cycles = 4, illegal = false },
	[0xBC] = { opcode = 0xBC, mnemonic = "LDY", operation = ops.LDY, mode = "ABX", cycles = 4, illegal = false },

	-- BPL
	[0x10] = { opcode = 0x10, mnemonic = "BPL", operation = ops.BPL, mode = "REL", cycles = 2, illegal = false },

	-- CLD
	[0xD8] = { opcode = 0xD8, mnemonic = "CLD", operation = ops.CLD, mode = "IMP", cycles = 2, illegal = false },

	-- SBC
	[0xE1] = { opcode = 0xE1, mnemonic = "SBC", operation = ops.SBC, mode = "IZX", cycles = 6, illegal = false },
	[0xE5] = { opcode = 0xE5, mnemonic = "SBC", operation = ops.SBC, mode = "ZP0", cycles = 3, illegal = false },
	[0xE9] = { opcode = 0xE9, mnemonic = "SBC", operation = ops.SBC, mode = "IMM", cycles = 2, illegal = false },
	[0xEB] = { opcode = 0xEB, mnemonic = "SBC", operation = ops.SBC, mode = "IMM", cycles = 2, illegal = true },
	[0xED] = { opcode = 0xED, mnemonic = "SBC", operation = ops.SBC, mode = "ABS", cycles = 4, illegal = false },
	[0xF1] = { opcode = 0xF1, mnemonic = "SBC", operation = ops.SBC, mode = "IZY", cycles = 5, illegal = false },
	[0xF5] = { opcode = 0xF5, mnemonic = "SBC", operation = ops.SBC, mode = "ZPX", cycles = 4, illegal = false },
	[0xF9] = { opcode = 0xF9, mnemonic = "SBC", operation = ops.SBC, mode = "ABY", cycles = 4, illegal = false },
	[0xFD] = { opcode = 0xFD, mnemonic = "SBC", operation = ops.SBC, mode = "ABX", cycles = 4, illegal = false },

	-- STX
	[0x86] = { opcode = 0x86, mnemonic = "STX", operation = ops.STX, mode = "ZP0", cycles = 3, illegal = false },
	[0x8E] = { opcode = 0x8E, mnemonic = "STX", operation = ops.STX, mode = "ABS", cycles = 4, illegal = false },
	[0x96] = { opcode = 0x96, mnemonic = "STX", operation = ops.STX, mode = "ZPY", cycles = 4, illegal = false },

	-- CLI
	[0x58] = { opcode = 0x58, mnemonic = "CLI", operation = ops.CLI, mode = "IMP", cycles = 2, illegal = false },

	-- SHY
	--[0x9C] = { opcode = 0x9C, mnemonic = "SHY", operation = ops.SHY, mode = "ABX", cycles = 5, illegal = true },

	-- BCC
	[0x90] = { opcode = 0x90, mnemonic = "BCC", operation = ops.BCC, mode = "REL", cycles = 2, illegal = false },

	-- PLP
	[0x28] = { opcode = 0x28, mnemonic = "PLP", operation = ops.PLP, mode = "IMP", cycles = 4, illegal = false },

	-- SHX
	--[0x9E] = { opcode = 0x9E, mnemonic = "SHX", operation = ops.SHX, mode = "ABY", cycles = 5, illegal = true },

	-- EOR
	[0x41] = { opcode = 0x41, mnemonic = "EOR", operation = ops.EOR, mode = "IZX", cycles = 6, illegal = false },
	[0x45] = { opcode = 0x45, mnemonic = "EOR", operation = ops.EOR, mode = "ZP0", cycles = 3, illegal = false },
	[0x49] = { opcode = 0x49, mnemonic = "EOR", operation = ops.EOR, mode = "IMM", cycles = 2, illegal = false },
	[0x4D] = { opcode = 0x4D, mnemonic = "EOR", operation = ops.EOR, mode = "ABS", cycles = 4, illegal = false },
	[0x51] = { opcode = 0x51, mnemonic = "EOR", operation = ops.EOR, mode = "IZY", cycles = 5, illegal = false },
	[0x55] = { opcode = 0x55, mnemonic = "EOR", operation = ops.EOR, mode = "ZPX", cycles = 4, illegal = false },
	[0x59] = { opcode = 0x59, mnemonic = "EOR", operation = ops.EOR, mode = "ABY", cycles = 4, illegal = false },
	[0x5D] = { opcode = 0x5D, mnemonic = "EOR", operation = ops.EOR, mode = "ABX", cycles = 4, illegal = false },

	-- JAM
	[0x02] = { opcode = 0x02, mnemonic = "JAM", operation = ops.JAM, mode = "IMP", cycles = 0, illegal = true },
	[0x12] = { opcode = 0x12, mnemonic = "JAM", operation = ops.JAM, mode = "IMP", cycles = 0, illegal = true },
	[0x22] = { opcode = 0x22, mnemonic = "JAM", operation = ops.JAM, mode = "IMP", cycles = 0, illegal = true },
	[0x32] = { opcode = 0x32, mnemonic = "JAM", operation = ops.JAM, mode = "IMP", cycles = 0, illegal = true },
	[0x42] = { opcode = 0x42, mnemonic = "JAM", operation = ops.JAM, mode = "IMP", cycles = 0, illegal = true },
	[0x52] = { opcode = 0x52, mnemonic = "JAM", operation = ops.JAM, mode = "IMP", cycles = 0, illegal = true },
	[0x62] = { opcode = 0x62, mnemonic = "JAM", operation = ops.JAM, mode = "IMP", cycles = 0, illegal = true },
	[0x72] = { opcode = 0x72, mnemonic = "JAM", operation = ops.JAM, mode = "IMP", cycles = 0, illegal = true },
	[0x92] = { opcode = 0x92, mnemonic = "JAM", operation = ops.JAM, mode = "IMP", cycles = 0, illegal = true },
	[0xB2] = { opcode = 0xB2, mnemonic = "JAM", operation = ops.JAM, mode = "IMP", cycles = 0, illegal = true },
	[0xD2] = { opcode = 0xD2, mnemonic = "JAM", operation = ops.JAM, mode = "IMP", cycles = 0, illegal = true },
	[0xF2] = { opcode = 0xF2, mnemonic = "JAM", operation = ops.JAM, mode = "IMP", cycles = 0, illegal = true },

	-- CLC
	[0x18] = { opcode = 0x18, mnemonic = "CLC", operation = ops.CLC, mode = "IMP", cycles = 2, illegal = false },

	-- PHP
	[0x08] = { opcode = 0x08, mnemonic = "PHP", operation = ops.PHP, mode = "IMP", cycles = 3, illegal = false },

	-- DEY
	[0x88] = { opcode = 0x88, mnemonic = "DEY", operation = ops.DEY, mode = "IMP", cycles = 2, illegal = false },

	-- TSX
	[0xBA] = { opcode = 0xBA, mnemonic = "TSX", operation = ops.TSX, mode = "IMP", cycles = 2, illegal = false },

	-- SEI
	[0x78] = { opcode = 0x78, mnemonic = "SEI", operation = ops.SEI, mode = "IMP", cycles = 2, illegal = false },

	-- BMI
	[0x30] = { opcode = 0x30, mnemonic = "BMI", operation = ops.BMI, mode = "REL", cycles = 2, illegal = false },

	-- ROR
	[0x66] = { opcode = 0x66, mnemonic = "ROR", operation = ops.ROR, mode = "ZP0", cycles = 5, illegal = false },
	[0x6A] = { opcode = 0x6A, mnemonic = "ROR", operation = ops.ROR, mode = "ACC", cycles = 2, illegal = false },
	[0x6E] = { opcode = 0x6E, mnemonic = "ROR", operation = ops.ROR, mode = "ABS", cycles = 6, illegal = false },
	[0x76] = { opcode = 0x76, mnemonic = "ROR", operation = ops.ROR, mode = "ZPX", cycles = 6, illegal = false },
	[0x7E] = { opcode = 0x7E, mnemonic = "ROR", operation = ops.ROR, mode = "ABX", cycles = 7, illegal = false },

	-- ADC
	[0x61] = { opcode = 0x61, mnemonic = "ADC", operation = ops.ADC, mode = "IZX", cycles = 6, illegal = false },
	[0x65] = { opcode = 0x65, mnemonic = "ADC", operation = ops.ADC, mode = "ZP0", cycles = 3, illegal = false },
	[0x69] = { opcode = 0x69, mnemonic = "ADC", operation = ops.ADC, mode = "IMM", cycles = 2, illegal = false },
	[0x6D] = { opcode = 0x6D, mnemonic = "ADC", operation = ops.ADC, mode = "ABS", cycles = 4, illegal = false },
	[0x71] = { opcode = 0x71, mnemonic = "ADC", operation = ops.ADC, mode = "IZY", cycles = 5, illegal = false },
	[0x75] = { opcode = 0x75, mnemonic = "ADC", operation = ops.ADC, mode = "ZPX", cycles = 4, illegal = false },
	[0x79] = { opcode = 0x79, mnemonic = "ADC", operation = ops.ADC, mode = "ABY", cycles = 4, illegal = false },
	[0x7D] = { opcode = 0x7D, mnemonic = "ADC", operation = ops.ADC, mode = "ABX", cycles = 4, illegal = false },

	-- LSR
	[0x46] = { opcode = 0x46, mnemonic = "LSR", operation = ops.LSR, mode = "ZP0", cycles = 5, illegal = false },
	[0x4A] = { opcode = 0x4A, mnemonic = "LSR", operation = ops.LSR, mode = "ACC", cycles = 2, illegal = false },
	[0x4E] = { opcode = 0x4E, mnemonic = "LSR", operation = ops.LSR, mode = "ABS", cycles = 6, illegal = false },
	[0x56] = { opcode = 0x56, mnemonic = "LSR", operation = ops.LSR, mode = "ZPX", cycles = 6, illegal = false },
	[0x5E] = { opcode = 0x5E, mnemonic = "LSR", operation = ops.LSR, mode = "ABX", cycles = 7, illegal = false },

	-- JSR
	[0x20] = { opcode = 0x20, mnemonic = "JSR", operation = ops.JSR, mode = "ABS", cycles = 6, illegal = false },

	-- BVS
	[0x70] = { opcode = 0x70, mnemonic = "BVS", operation = ops.BVS, mode = "REL", cycles = 2, illegal = false },

	-- RRA
	--[0x63] = { opcode = 0x63, mnemonic = "RRA", operation = ops.RRA, mode = "IZX", cycles = 8, illegal = true },
	--[0x67] = { opcode = 0x67, mnemonic = "RRA", operation = ops.RRA, mode = "ZP0", cycles = 5, illegal = true },
	--[0x6F] = { opcode = 0x6F, mnemonic = "RRA", operation = ops.RRA, mode = "ABS", cycles = 6, illegal = true },
	--[0x73] = { opcode = 0x73, mnemonic = "RRA", operation = ops.RRA, mode = "IZY", cycles = 8, illegal = true },
	--[0x77] = { opcode = 0x77, mnemonic = "RRA", operation = ops.RRA, mode = "ZPX", cycles = 6, illegal = true },
	--[0x7B] = { opcode = 0x7B, mnemonic = "RRA", operation = ops.RRA, mode = "ABY", cycles = 7, illegal = true },
	--[0x7F] = { opcode = 0x7F, mnemonic = "RRA", operation = ops.RRA, mode = "ABX", cycles = 7, illegal = true },

	-- ALR
	--[0x4B] = { opcode = 0x4B, mnemonic = "ALR", operation = ops.ALR, mode = "IMM", cycles = 2, illegal = true },

	-- SAX
	--[0x83] = { opcode = 0x83, mnemonic = "SAX", operation = ops.SAX, mode = "IZX", cycles = 6, illegal = true },
	--[0x87] = { opcode = 0x87, mnemonic = "SAX", operation = ops.SAX, mode = "ZP0", cycles = 3, illegal = true },
	--[0x8F] = { opcode = 0x8F, mnemonic = "SAX", operation = ops.SAX, mode = "ABS", cycles = 4, illegal = true },
	--[0x97] = { opcode = 0x97, mnemonic = "SAX", operation = ops.SAX, mode = "ZPY", cycles = 4, illegal = true },

	-- TAX
	[0xAA] = { opcode = 0xAA, mnemonic = "TAX", operation = ops.TAX, mode = "IMP", cycles = 2, illegal = false },

	-- LXA
	--[0xAB] = { opcode = 0xAB, mnemonic = "LXA", operation = ops.LXA, mode = "IMM", cycles = 2, illegal = true },

	-- SRE
	--[0x43] = { opcode = 0x43, mnemonic = "SRE", operation = ops.SRE, mode = "IZX", cycles = 8, illegal = true },
	--[0x47] = { opcode = 0x47, mnemonic = "SRE", operation = ops.SRE, mode = "ZP0", cycles = 5, illegal = true },
	--[0x4F] = { opcode = 0x4F, mnemonic = "SRE", operation = ops.SRE, mode = "ABS", cycles = 6, illegal = true },
	--[0x53] = { opcode = 0x53, mnemonic = "SRE", operation = ops.SRE, mode = "IZY", cycles = 8, illegal = true },
	--[0x57] = { opcode = 0x57, mnemonic = "SRE", operation = ops.SRE, mode = "ZPX", cycles = 6, illegal = true },
	--[0x5B] = { opcode = 0x5B, mnemonic = "SRE", operation = ops.SRE, mode = "ABY", cycles = 7, illegal = true },
	--[0x5F] = { opcode = 0x5F, mnemonic = "SRE", operation = ops.SRE, mode = "ABX", cycles = 7, illegal = true },

	-- STY
	[0x84] = { opcode = 0x84, mnemonic = "STY", operation = ops.STY, mode = "ZP0", cycles = 3, illegal = false },
	[0x8C] = { opcode = 0x8C, mnemonic = "STY", operation = ops.STY, mode = "ABS", cycles = 4, illegal = false },
	[0x94] = { opcode = 0x94, mnemonic = "STY", operation = ops.STY, mode = "ZPX", cycles = 4, illegal = false },

	-- INY
	[0xC8] = { opcode = 0xC8, mnemonic = "INY", operation = ops.INY, mode = "IMP", cycles = 2, illegal = false },

	-- ORA
	[0x01] = { opcode = 0x01, mnemonic = "ORA", operation = ops.ORA, mode = "IZX", cycles = 6, illegal = false },
	[0x05] = { opcode = 0x05, mnemonic = "ORA", operation = ops.ORA, mode = "ZP0", cycles = 3, illegal = false },
	[0x09] = { opcode = 0x09, mnemonic = "ORA", operation = ops.ORA, mode = "IMM", cycles = 2, illegal = false },
	[0x0D] = { opcode = 0x0D, mnemonic = "ORA", operation = ops.ORA, mode = "ABS", cycles = 4, illegal = false },
	[0x11] = { opcode = 0x11, mnemonic = "ORA", operation = ops.ORA, mode = "IZY", cycles = 5, illegal = false },
	[0x15] = { opcode = 0x15, mnemonic = "ORA", operation = ops.ORA, mode = "ZPX", cycles = 4, illegal = false },
	[0x19] = { opcode = 0x19, mnemonic = "ORA", operation = ops.ORA, mode = "ABY", cycles = 4, illegal = false },
	[0x1D] = { opcode = 0x1D, mnemonic = "ORA", operation = ops.ORA, mode = "ABX", cycles = 4, illegal = false },

	-- TXA
	[0x8A] = { opcode = 0x8A, mnemonic = "TXA", operation = ops.TXA, mode = "IMP", cycles = 2, illegal = false },

	-- SLO
	--[0x03] = { opcode = 0x03, mnemonic = "SLO", operation = ops.SLO, mode = "IZX", cycles = 8, illegal = true },
	--[0x07] = { opcode = 0x07, mnemonic = "SLO", operation = ops.SLO, mode = "ZP0", cycles = 5, illegal = true },
	--[0x0F] = { opcode = 0x0F, mnemonic = "SLO", operation = ops.SLO, mode = "ABS", cycles = 6, illegal = true },
	--[0x13] = { opcode = 0x13, mnemonic = "SLO", operation = ops.SLO, mode = "IZY", cycles = 8, illegal = true },
	--[0x17] = { opcode = 0x17, mnemonic = "SLO", operation = ops.SLO, mode = "ZPX", cycles = 6, illegal = true },
	--[0x1B] = { opcode = 0x1B, mnemonic = "SLO", operation = ops.SLO, mode = "ABY", cycles = 7, illegal = true },
	--[0x1F] = { opcode = 0x1F, mnemonic = "SLO", operation = ops.SLO, mode = "ABX", cycles = 7, illegal = true },

	-- ANE
	--[0x8B] = { opcode = 0x8B, mnemonic = "ANE", operation = ops.ANE, mode = "IMM", cycles = 2, illegal = true },

	-- TXS
	[0x9A] = { opcode = 0x9A, mnemonic = "TXS", operation = ops.TXS, mode = "IMP", cycles = 2, illegal = false },

	-- BNE
	[0xD0] = { opcode = 0xD0, mnemonic = "BNE", operation = ops.BNE, mode = "REL", cycles = 2, illegal = false },

	-- CPX
	[0xE0] = { opcode = 0xE0, mnemonic = "CPX", operation = ops.CPX, mode = "IMM", cycles = 2, illegal = false },
	[0xE4] = { opcode = 0xE4, mnemonic = "CPX", operation = ops.CPX, mode = "ZP0", cycles = 3, illegal = false },
	[0xEC] = { opcode = 0xEC, mnemonic = "CPX", operation = ops.CPX, mode = "ABS", cycles = 4, illegal = false },

	-- ROL
	[0x26] = { opcode = 0x26, mnemonic = "ROL", operation = ops.ROL, mode = "ZP0", cycles = 5, illegal = false },
	[0x2A] = { opcode = 0x2A, mnemonic = "ROL", operation = ops.ROL, mode = "ACC", cycles = 2, illegal = false },
	[0x2E] = { opcode = 0x2E, mnemonic = "ROL", operation = ops.ROL, mode = "ABS", cycles = 6, illegal = false },
	[0x36] = { opcode = 0x36, mnemonic = "ROL", operation = ops.ROL, mode = "ZPX", cycles = 6, illegal = false },
	[0x3E] = { opcode = 0x3E, mnemonic = "ROL", operation = ops.ROL, mode = "ABX", cycles = 7, illegal = false },

	-- LAX
	--[0xA3] = { opcode = 0xA3, mnemonic = "LAX", operation = ops.LAX, mode = "IZX", cycles = 6, illegal = true },
	--[0xA7] = { opcode = 0xA7, mnemonic = "LAX", operation = ops.LAX, mode = "ZP0", cycles = 3, illegal = true },
	--[0xAF] = { opcode = 0xAF, mnemonic = "LAX", operation = ops.LAX, mode = "ABS", cycles = 4, illegal = true },
	--[0xB3] = { opcode = 0xB3, mnemonic = "LAX", operation = ops.LAX, mode = "IZY", cycles = 5, illegal = true },
	--[0xB7] = { opcode = 0xB7, mnemonic = "LAX", operation = ops.LAX, mode = "ZPY", cycles = 4, illegal = true },
	--[0xBF] = { opcode = 0xBF, mnemonic = "LAX", operation = ops.LAX, mode = "ABY", cycles = 4, illegal = true },

	-- ANC
	--[0x0B] = { opcode = 0x0B, mnemonic = "ANC", operation = ops.ANC, mode = "IMM", cycles = 2, illegal = true },
	--[0x2B] = { opcode = 0x2B, mnemonic = "ANC", operation = ops.ANC, mode = "IMM", cycles = 2, illegal = true },

	-- BRK
	[0x00] = { opcode = 0x00, mnemonic = "BRK", operation = ops.BRK, mode = "IMP", cycles = 7, illegal = false },

	-- SED
	[0xF8] = { opcode = 0xF8, mnemonic = "SED", operation = ops.SED, mode = "IMP", cycles = 2, illegal = false },

	-- INX
	[0xE8] = { opcode = 0xE8, mnemonic = "INX", operation = ops.INX, mode = "IMP", cycles = 2, illegal = false },

	-- SBX
	--[0xCB] = { opcode = 0xCB, mnemonic = "SBX", operation = ops.SBX, mode = "IMM", cycles = 2, illegal = true },

	-- BVC
	[0x50] = { opcode = 0x50, mnemonic = "BVC", operation = ops.BVC, mode = "REL", cycles = 2, illegal = false },

	-- INC
	[0xE6] = { opcode = 0xE6, mnemonic = "INC", operation = ops.INC, mode = "ZP0", cycles = 5, illegal = false },
	[0xEE] = { opcode = 0xEE, mnemonic = "INC", operation = ops.INC, mode = "ABS", cycles = 6, illegal = false },
	[0xF6] = { opcode = 0xF6, mnemonic = "INC", operation = ops.INC, mode = "ZPX", cycles = 6, illegal = false },
	[0xFE] = { opcode = 0xFE, mnemonic = "INC", operation = ops.INC, mode = "ABX", cycles = 7, illegal = false },

	-- BEQ
	[0xF0] = { opcode = 0xF0, mnemonic = "BEQ", operation = ops.BEQ, mode = "REL", cycles = 2, illegal = false },

	-- ISC
	--[0xE3] = { opcode = 0xE3, mnemonic = "ISC", operation = ops.ISC, mode = "IZX", cycles = 8, illegal = true },
	--[0xE7] = { opcode = 0xE7, mnemonic = "ISC", operation = ops.ISC, mode = "ZP0", cycles = 5, illegal = true },
	--[0xEF] = { opcode = 0xEF, mnemonic = "ISC", operation = ops.ISC, mode = "ABS", cycles = 6, illegal = true },
	--[0xF3] = { opcode = 0xF3, mnemonic = "ISC", operation = ops.ISC, mode = "IZY", cycles = 8, illegal = true },
	--[0xF7] = { opcode = 0xF7, mnemonic = "ISC", operation = ops.ISC, mode = "ZPX", cycles = 6, illegal = true },
	--[0xFB] = { opcode = 0xFB, mnemonic = "ISC", operation = ops.ISC, mode = "ABY", cycles = 7, illegal = true },
	--[0xFF] = { opcode = 0xFF, mnemonic = "ISC", operation = ops.ISC, mode = "ABX", cycles = 7, illegal = true },

	-- SEC
	[0x38] = { opcode = 0x38, mnemonic = "SEC", operation = ops.SEC, mode = "IMP", cycles = 2, illegal = false },

	-- ASL
	[0x06] = { opcode = 0x06, mnemonic = "ASL", operation = ops.ASL, mode = "ZP0", cycles = 5, illegal = false },
	[0x0A] = { opcode = 0x0A, mnemonic = "ASL", operation = ops.ASL, mode = "ACC", cycles = 2, illegal = false },
	[0x0E] = { opcode = 0x0E, mnemonic = "ASL", operation = ops.ASL, mode = "ABS", cycles = 6, illegal = false },
	[0x16] = { opcode = 0x16, mnemonic = "ASL", operation = ops.ASL, mode = "ZPX", cycles = 6, illegal = false },
	[0x1E] = { opcode = 0x1E, mnemonic = "ASL", operation = ops.ASL, mode = "ABX", cycles = 7, illegal = false },

	-- DEX
	[0xCA] = { opcode = 0xCA, mnemonic = "DEX", operation = ops.DEX, mode = "IMP", cycles = 2, illegal = false },

	-- RTS
	[0x60] = { opcode = 0x60, mnemonic = "RTS", operation = ops.RTS, mode = "IMP", cycles = 6, illegal = false },

	-- NOP
	[0x04] = { opcode = 0x04, mnemonic = "NOP", operation = ops.NOP, mode = "ZP0", cycles = 3, illegal = true },
	[0x0C] = { opcode = 0x0C, mnemonic = "NOP", operation = ops.NOP, mode = "ABS", cycles = 4, illegal = true },
	[0x14] = { opcode = 0x14, mnemonic = "NOP", operation = ops.NOP, mode = "ZPX", cycles = 4, illegal = true },
	[0x1A] = { opcode = 0x1A, mnemonic = "NOP", operation = ops.NOP, mode = "IMP", cycles = 2, illegal = true },
	[0x1C] = { opcode = 0x1C, mnemonic = "NOP", operation = ops.NOP, mode = "ABX", cycles = 4, illegal = true },
	[0x34] = { opcode = 0x34, mnemonic = "NOP", operation = ops.NOP, mode = "ZPX", cycles = 4, illegal = true },
	[0x3A] = { opcode = 0x3A, mnemonic = "NOP", operation = ops.NOP, mode = "IMP", cycles = 2, illegal = true },
	[0x3C] = { opcode = 0x3C, mnemonic = "NOP", operation = ops.NOP, mode = "ABX", cycles = 4, illegal = true },
	[0x44] = { opcode = 0x44, mnemonic = "NOP", operation = ops.NOP, mode = "ZP0", cycles = 3, illegal = true },
	[0x54] = { opcode = 0x54, mnemonic = "NOP", operation = ops.NOP, mode = "ZPX", cycles = 4, illegal = true },
	[0x5A] = { opcode = 0x5A, mnemonic = "NOP", operation = ops.NOP, mode = "IMP", cycles = 2, illegal = true },
	[0x5C] = { opcode = 0x5C, mnemonic = "NOP", operation = ops.NOP, mode = "ABX", cycles = 4, illegal = true },
	[0x64] = { opcode = 0x64, mnemonic = "NOP", operation = ops.NOP, mode = "ZP0", cycles = 3, illegal = true },
	[0x74] = { opcode = 0x74, mnemonic = "NOP", operation = ops.NOP, mode = "ZPX", cycles = 4, illegal = true },
	[0x7A] = { opcode = 0x7A, mnemonic = "NOP", operation = ops.NOP, mode = "IMP", cycles = 2, illegal = true },
	[0x7C] = { opcode = 0x7C, mnemonic = "NOP", operation = ops.NOP, mode = "ABX", cycles = 4, illegal = true },
	[0x80] = { opcode = 0x80, mnemonic = "NOP", operation = ops.NOP, mode = "IMM", cycles = 2, illegal = true },
	[0x82] = { opcode = 0x82, mnemonic = "NOP", operation = ops.NOP, mode = "IMM", cycles = 2, illegal = true },
	[0x89] = { opcode = 0x89, mnemonic = "NOP", operation = ops.NOP, mode = "IMM", cycles = 2, illegal = true },
	[0xC2] = { opcode = 0xC2, mnemonic = "NOP", operation = ops.NOP, mode = "IMM", cycles = 2, illegal = true },
	[0xD4] = { opcode = 0xD4, mnemonic = "NOP", operation = ops.NOP, mode = "ZPX", cycles = 4, illegal = true },
	[0xDA] = { opcode = 0xDA, mnemonic = "NOP", operation = ops.NOP, mode = "IMP", cycles = 2, illegal = true },
	[0xDC] = { opcode = 0xDC, mnemonic = "NOP", operation = ops.NOP, mode = "ABX", cycles = 4, illegal = true },
	[0xE2] = { opcode = 0xE2, mnemonic = "NOP", operation = ops.NOP, mode = "IMM", cycles = 2, illegal = true },
	[0xEA] = { opcode = 0xEA, mnemonic = "NOP", operation = ops.NOP, mode = "IMP", cycles = 2, illegal = false },
	[0xF4] = { opcode = 0xF4, mnemonic = "NOP", operation = ops.NOP, mode = "ZPX", cycles = 4, illegal = true },
	[0xFA] = { opcode = 0xFA, mnemonic = "NOP", operation = ops.NOP, mode = "IMP", cycles = 2, illegal = true },
	[0xFC] = { opcode = 0xFC, mnemonic = "NOP", operation = ops.NOP, mode = "ABX", cycles = 4, illegal = true },

	-- RLA
	--[0x23] = { opcode = 0x23, mnemonic = "RLA", operation = ops.RLA, mode = "IZX", cycles = 8, illegal = true },
	--[0x27] = { opcode = 0x27, mnemonic = "RLA", operation = ops.RLA, mode = "ZP0", cycles = 5, illegal = true },
	--[0x2F] = { opcode = 0x2F, mnemonic = "RLA", operation = ops.RLA, mode = "ABS", cycles = 6, illegal = true },
	--[0x33] = { opcode = 0x33, mnemonic = "RLA", operation = ops.RLA, mode = "IZY", cycles = 8, illegal = true },
	--[0x37] = { opcode = 0x37, mnemonic = "RLA", operation = ops.RLA, mode = "ZPX", cycles = 6, illegal = true },
	--[0x3B] = { opcode = 0x3B, mnemonic = "RLA", operation = ops.RLA, mode = "ABY", cycles = 7, illegal = true },
	--[0x3F] = { opcode = 0x3F, mnemonic = "RLA", operation = ops.RLA, mode = "ABX", cycles = 7, illegal = true },

	-- RTI
	[0x40] = { opcode = 0x40, mnemonic = "RTI", operation = ops.RTI, mode = "IMP", cycles = 6, illegal = false },

	-- PHA
	[0x48] = { opcode = 0x48, mnemonic = "PHA", operation = ops.PHA, mode = "IMP", cycles = 3, illegal = false },

	-- DEC
	[0xC6] = { opcode = 0xC6, mnemonic = "DEC", operation = ops.DEC, mode = "ZP0", cycles = 5, illegal = false },
	[0xCE] = { opcode = 0xCE, mnemonic = "DEC", operation = ops.DEC, mode = "ABS", cycles = 6, illegal = false },
	[0xD6] = { opcode = 0xD6, mnemonic = "DEC", operation = ops.DEC, mode = "ZPX", cycles = 6, illegal = false },
	[0xDE] = { opcode = 0xDE, mnemonic = "DEC", operation = ops.DEC, mode = "ABX", cycles = 7, illegal = false },

	-- DCP
	--[0xC3] = { opcode = 0xC3, mnemonic = "DCP", operation = ops.DCP, mode = "IZX", cycles = 8, illegal = true },
	--[0xC7] = { opcode = 0xC7, mnemonic = "DCP", operation = ops.DCP, mode = "ZP0", cycles = 5, illegal = true },
	--[0xCF] = { opcode = 0xCF, mnemonic = "DCP", operation = ops.DCP, mode = "ABS", cycles = 6, illegal = true },
	--[0xD3] = { opcode = 0xD3, mnemonic = "DCP", operation = ops.DCP, mode = "IZY", cycles = 8, illegal = true },
	--[0xD7] = { opcode = 0xD7, mnemonic = "DCP", operation = ops.DCP, mode = "ZPX", cycles = 6, illegal = true },
	--[0xDB] = { opcode = 0xDB, mnemonic = "DCP", operation = ops.DCP, mode = "ABY", cycles = 7, illegal = true },
	--[0xDF] = { opcode = 0xDF, mnemonic = "DCP", operation = ops.DCP, mode = "ABX", cycles = 7, illegal = true },

	-- PLA
	[0x68] = { opcode = 0x68, mnemonic = "PLA", operation = ops.PLA, mode = "IMP", cycles = 4, illegal = false },

	-- TAS
	--[0x9B] = { opcode = 0x9B, mnemonic = "TAS", operation = ops.TAS, mode = "ABY", cycles = 5, illegal = true },

	-- CMP
	[0xC1] = { opcode = 0xC1, mnemonic = "CMP", operation = ops.CMP, mode = "IZX", cycles = 6, illegal = false },
	[0xC5] = { opcode = 0xC5, mnemonic = "CMP", operation = ops.CMP, mode = "ZP0", cycles = 3, illegal = false },
	[0xC9] = { opcode = 0xC9, mnemonic = "CMP", operation = ops.CMP, mode = "IMM", cycles = 2, illegal = false },
	[0xCD] = { opcode = 0xCD, mnemonic = "CMP", operation = ops.CMP, mode = "ABS", cycles = 4, illegal = false },
	[0xD1] = { opcode = 0xD1, mnemonic = "CMP", operation = ops.CMP, mode = "IZY", cycles = 5, illegal = false },
	[0xD5] = { opcode = 0xD5, mnemonic = "CMP", operation = ops.CMP, mode = "ZPX", cycles = 4, illegal = false },
	[0xD9] = { opcode = 0xD9, mnemonic = "CMP", operation = ops.CMP, mode = "ABY", cycles = 4, illegal = false },
	[0xDD] = { opcode = 0xDD, mnemonic = "CMP", operation = ops.CMP, mode = "ABX", cycles = 4, illegal = false },

	-- AND
	[0x21] = { opcode = 0x21, mnemonic = "AND", operation = ops.AND, mode = "IZX", cycles = 6, illegal = false },
	[0x25] = { opcode = 0x25, mnemonic = "AND", operation = ops.AND, mode = "ZP0", cycles = 3, illegal = false },
	[0x29] = { opcode = 0x29, mnemonic = "AND", operation = ops.AND, mode = "IMM", cycles = 2, illegal = false },
	[0x2D] = { opcode = 0x2D, mnemonic = "AND", operation = ops.AND, mode = "ABS", cycles = 4, illegal = false },
	[0x31] = { opcode = 0x31, mnemonic = "AND", operation = ops.AND, mode = "IZY", cycles = 5, illegal = false },
	[0x35] = { opcode = 0x35, mnemonic = "AND", operation = ops.AND, mode = "ZPX", cycles = 4, illegal = false },
	[0x39] = { opcode = 0x39, mnemonic = "AND", operation = ops.AND, mode = "ABY", cycles = 4, illegal = false },
	[0x3D] = { opcode = 0x3D, mnemonic = "AND", operation = ops.AND, mode = "ABX", cycles = 4, illegal = false },

	-- JMP
	[0x4C] = { opcode = 0x4C, mnemonic = "JMP", operation = ops.JMP, mode = "ABS", cycles = 3, illegal = false },
	[0x6C] = { opcode = 0x6C, mnemonic = "JMP", operation = ops.JMP, mode = "IND", cycles = 5, illegal = false },

	-- BCS
	[0xB0] = { opcode = 0xB0, mnemonic = "BCS", operation = ops.BCS, mode = "REL", cycles = 2, illegal = false },

	-- TAY
	[0xA8] = { opcode = 0xA8, mnemonic = "TAY", operation = ops.TAY, mode = "IMP", cycles = 2, illegal = false },

	-- LDX
	[0xA2] = { opcode = 0xA2, mnemonic = "LDX", operation = ops.LDX, mode = "IMM", cycles = 2, illegal = false },
	[0xA6] = { opcode = 0xA6, mnemonic = "LDX", operation = ops.LDX, mode = "ZP0", cycles = 3, illegal = false },
	[0xAE] = { opcode = 0xAE, mnemonic = "LDX", operation = ops.LDX, mode = "ABS", cycles = 4, illegal = false },
	[0xB6] = { opcode = 0xB6, mnemonic = "LDX", operation = ops.LDX, mode = "ZPY", cycles = 4, illegal = false },
	[0xBE] = { opcode = 0xBE, mnemonic = "LDX", operation = ops.LDX, mode = "ABY", cycles = 4, illegal = false },

	-- TYA
	[0x98] = { opcode = 0x98, mnemonic = "TYA", operation = ops.TYA, mode = "IMP", cycles = 2, illegal = false },

	-- LAS
	--[0xBB] = { opcode = 0xBB, mnemonic = "LAS", operation = ops.LAS, mode = "ABY", cycles = 4, illegal = true },

	-- BIT
	[0x24] = { opcode = 0x24, mnemonic = "BIT", operation = ops.BIT, mode = "ZP0", cycles = 3, illegal = false },
	[0x2C] = { opcode = 0x2C, mnemonic = "BIT", operation = ops.BIT, mode = "ABS", cycles = 4, illegal = false },
}

local cpu = {}

function cpu.create(memory: Bus): Cpu
	local cpu = {
		A = 0,
		X = 0,
		Y = 0,
		P = 0,
		S = 0,
		PC = 0,

		jammed = false,

		pending_reset = false,
		pending_nmi = false,
		pending_irq = false,

		cycles = 0,
	}

	handle_reset(cpu, memory)

	return cpu
end

--[=[
	Steps a single instruction.
]=]
function cpu.step(cpu: Cpu, memory: Bus)
	if cpu.pending_reset then
		handle_reset(cpu, memory)
		return
	end

	if cpu.jammed then
		return
	end

	if cpu.pending_nmi then
		handle_interrupt(cpu, memory, 0xFFFA)
		cpu.pending_nmi = false
		return
	end

	if cpu.pending_irq and not GET_FLAG(cpu.P, FLAG_I) then
		handle_interrupt(cpu, memory, 0xFFFE)
		cpu.pending_irq = false
		return
	end

	local opcode = fetch(cpu, memory)
	local insn = instructions[opcode]
	if not insn then
		error(`opcode 0x{string.format("%02X", opcode)} not implemented`)
	end

	local additional_cycles = insn.operation(cpu, memory, insn.mode)
	cycle(cpu, insn.cycles + additional_cycles)
end

function cpu.reset(cpu: Cpu)
	cpu.pending_reset = true
end

function cpu.interrupt(cpu: Cpu, type: "irq" | "nmi")
	if type == "irq" then
		cpu.pending_irq = true
	elseif type == "nmi" then
		cpu.pending_nmi = true
	end
end

function cpu.status(cpu: Cpu): string
	return string.format("pc=0x%04x", cpu.PC)
end

return cpu
