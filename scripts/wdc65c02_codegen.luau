local Wdc65c02 = require("../src/Wdc65c02")

--[[
    This program generates the instruction implementations for the wdc65c02
    instruction set.

    The following values are always available:
    `A: u8`, `X: u8`, `Y: u8`, `S: u8`, `PC: u16`
    `NZ: u8`, `V: boolean`, `B: boolean`, `D: boolean`, `I: boolean`, `C: boolean`
    `read: (u16) -> u8`
    `write: (u16, u16) -> ()`
    `get_p: () -> u8`
    `set_p: (u8) -> ()`
    `push: (u8) -> ()`
    `pull: () -> u8`
    `concat_u16: (lo: u8, hi: u8) -> u16`
    `add_u8: (a: u8, b: u8) -> u8`
    `sub_u8: (a: u8, b: u8) -> u8`
    `add_u16: (a: u16, b: u16) -> u16`
    `sub_u16: (a: u16, b: u16) -> u16`
    `same_page: (a: u16, b: u16) -> boolean`
    `cycles_taken: number`

    Furthermore, the following values are made available by the address mode stub:

    `address: u16` (ACC, ABS, ABX, ABY, IND, IAX, ZP0, ZPX, ZPY, ZPI, IZX, ZXY, REL, ZPBn, ZPRn)
    `base_address: u16` (ACC, ABS, ABX, ABY, IND, IAX, ZP0, ZPX, ZPY, ZPI, IZX, ZXY, REL, ZPBn, ZPRn)
    `value: u8` (IMM, ACC, ABS, ABX, ABY, IND, IAX, ZP0, ZPX, ZPY, ZPI, IZX, ZXY, REL, ZPBn, ZPRn)
    `bit_offset: number` (ZPBn, ZPRn)

    If an implementation doesn't use `value` (checked via a simple string.find 
    call), the code to get it's value (by dereferencing memory) isn't emitted.
]]

local BINARY_SEARCH = true
local COMPACT = true

local MODES: { [string]: string } = {
	IMP = "",
	ACC = [[
local value = A
local address = nil
local base_address = nil
]],
	IMM = [[
local value = fetch()
local address = nil
local base_address = nil
]],
	ABS = [[
local base_address = concat_u16(fetch(), fetch())
local address = base_address
]],
	ABX = [[
local base_address = concat_u16(fetch(), fetch())
local address = add_u16(base_address, X)
if not same_page(base_address, address) then
    cycles_taken += 1
end
]],
	ABY = [[
local base_address = concat_u16(fetch(), fetch())
local address = add_u16(base_address, Y)
if not same_page(base_address, address) then
    cycles_taken += 1
end
]],
	IND = [[
local ptr = concat_u16(fetch(), fetch())
local base_address = concat_u16(read(ptr), read(add_u16(ptr, 1)))
local address = base_address
]],
	IAX = [[
local base_ptr = concat_u16(fetch(), fetch())
local indexed_ptr = add_u16(base_ptr, X)
local address = concat_u16(read(indexed_ptr), read(add_u16(indexed_ptr, 1)))
local base_address = base_ptr
]],
	ZP0 = [[
local base_address = fetch()
local address = base_address
]],
	ZPX = [[
local base_address = fetch()
local address = add_u8(base_address, X)
]],
	ZPY = [[
local base_address = fetch()
local address = add_u8(base_address, Y)
]],
	ZPI = [[
local ptr = fetch()
local base_address = concat_u16(read(ptr), read(add_u8(ptr, 1)))
local address = base_address
]],
	IZX = [[
local ptr = add_u8(fetch(), X)
local base_address = concat_u16(read(ptr), read(add_u8(ptr, 1)))
local address = base_address

]],
	IZY = [[
local ptr = fetch()
local base_address = concat_u16(read(ptr), read(add_u8(ptr, 1)))
local address = add_u16(base_address, Y)
if not same_page(base_address, address) then
    cycles_taken += 1
end
]],
	REL = [[
local offset = reinterpret_signed(fetch())
local base_address = PC
local address = add_u16(base_address, offset)
]],
}

for i = 0, 7 do
	MODES["ZPB" .. i] = string.format(
		[[
local address = fetch()
local bit_offset = %d
]],
		i
	)

	MODES["ZPR" .. i] = string.format(
		[[
local zp_addr = fetch()
local offset = fetch()
local bit_offset = %d
local rel = if offset > 127 then offset - 256 else offset
    
local base_address = zp_addr
local value = read(zp_addr)
local address = add_u16(PC, rel)
]],
		i
	)
end

local OPS: { [string]: string } = {
	LDA = [[
A = value
N, Z = value, value
]],
	LDX = [[
X = value
N, Z = value, value
]],
	LDY = [[
Y = value
N, Z = value, value
]],
	STA = [[
write(address, A)
]],
	STX = [[
write(address, X)
]],
	STY = [[
write(address, Y)
]],
	STZ = [[
write(address, 0)
]],
	TAX = [[
X = A
N, Z = X, X
]],
	TAY = [[
Y = A
N, Z = Y, Y
]],
	TSX = [[
X = S
]],
	TXA = [[
A = X
N, Z = A, A
]],
	TXS = [[
S = X
N, Z = S, S
]],
	TYA = [[
A = Y
N, Z = A, A
]],
	PHA = [[
push(A)
]],
	PHP = [[
push(bit32.bor(get_p(true), 0x30))
]],
	PHX = [[
push(X)
]],
	PHY = [[
push(Y)
]],
	PLA = [[
A = pull()
N, Z = A, A
]],
	PLP = [[
set_p(pull())
]],
	PLX = [[
X = pull()
N, Z = X, X
]],
	PLY = [[
Y = pull()
N, Z = Y, Y
]],
	ASL = [[
local result = bit32.lshift(value, 1)
C = bit32.band(result, 0x100) ~= 0
result = bit32.band(result, 0xFF)
write(address, result)
N, Z = result, result
]],
	LSR = [[
C = bit32.band(value, 0x01) ~= 0
local result = bit32.rshift(value, 1)
write(address, result)
N, Z = result, result
]],
	ROL = [[
local result = bit32.bor(bit32.lshift(value, 1), if C then 1 else 0)
C = bit32.band(result, 0x100) ~= 0
result = bit32.band(result, 0xFF)
write(address, result)
N, Z = result, result
]],
	ROR = [[
local result = bit32.bor(bit32.rshift(value, 1), if C then 0x80 else 0)
C = bit32.band(value, 0x01) ~= 0
write(address, result)
N, Z = result, result
]],
	AND = [[
A = bit32.band(value, A)
N, Z = A, A
]],
	BIT = [[
local res = bit32.band(A, value)
Z = res

if address then
    V = bit32.band(value, 0x40) ~= 0
    N = value
end
]],
	EOR = [[
A = bit32.bxor(value, A)
N, Z = A, A
]],
	ORA = [[
A = bit32.bor(value, A)
N, Z = A, A
]],
	TRB = [[
Z = bit32.band(A, value)
local result = bit32.bor(value, A)
write(address, result)
]],
	TSB = [[
Z = bit32.band(A, value)
local result = bit32.bor(A, value)
write(address, result)
]],
	ADC = [[
if not D then
    local result = A + value + (if C then 1 else 0)
    V = bit32.band(bit32.bxor(A, result), bit32.bxor(value, result), 0x80) ~= 0
    C = result > 0xFF
    A = bit32.band(result, 0xFF)
    N, Z = A, A
else
    cycles_taken += 1
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
]],
	CMP = [[
local result = sub_u8(A, value)
N, Z = result, result
C = value <= A
]],
	CPX = [[
local result = sub_u8(X, value)
N, Z = result, result
C = value <= X
]],
	CPY = [[
local result = sub_u8(Y, value)
N, Z = result, result
C = value <= Y
]],
	SBC = [[
    if not D then
        local inv_value = bit32.bxor(value, 0xFF)
        local result = A + inv_value + (if C then 1 else 0)
        V = bit32.band(bit32.bxor(A, result), bit32.bxor(inv_value, result), 0x80) ~= 0
        C = result > 0xFF
        A = bit32.band(result, 0xFF)
        N, Z = A, A
    else
        cycles_taken += 1
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
]],
	DEC = [[
local result = sub_u8(value, 1)
N, Z = result, result
write(address, result)
]],
	DEX = [[
X = sub_u8(X, 1)
N, Z = X, X
]],
	DEY = [[
Y = sub_u8(Y, 1)
N, Z = Y, Y
]],
	INC = [[
local result = add_u8(value, 1)
N, Z = result, result
write(address, result)
]],
	INX = [[
X = add_u8(X, 1)
N, Z = X, X
]],
	INY = [[
Y = add_u8(Y, 1)
N, Z = Y, Y
]],
	BRA = [[
if not same_page(base_address, address) then
    cycles_taken += 1
end
PC = address
]],
	BRK = [[
if self._irq and not I then
    continue
end

handle_interrupt(0xFFFE, true)
cycles_taken -= 7
]],
	JMP = [[
PC = address
]],
	JSR = [[
local return_address = sub_u16(PC, 1)
push(bit32.rshift(return_address, 8))
push(bit32.band(return_address, 0xFF))
PC = address
]],
	RTI = [[
set_p(pull())
PC = concat_u16(pull(), pull())
]],
	RTS = [[
PC = add_u16(concat_u16(pull(), pull()), 1)
]],
	BCC = [[
if not C then
    cycles_taken += if same_page(base_address, address) then 1 else 2
    PC = address
end
]],
	BCS = [[
if C then
    cycles_taken += if same_page(base_address, address) then 1 else 2
    PC = address
end
]],
	BEQ = [[
if Z == 0 then
    cycles_taken += if same_page(base_address, address) then 1 else 2
    PC = address
end
]],
	BMI = [[
if N >= 0x80 then
    cycles_taken += if same_page(base_address, address) then 1 else 2
    PC = address
end
]],
	BNE = [[
if Z ~= 0 then
    cycles_taken += if same_page(base_address, address) then 1 else 2
    PC = address
end
]],
	BPL = [[
if N < 0x80 then
    cycles_taken += if same_page(base_address, address) then 1 else 2
    PC = address
end
]],
	BVC = [[
if not V then
    cycles_taken += if same_page(base_address, address) then 1 else 2
    PC = address
end
]],
	BVS = [[
if V then
    cycles_taken += if same_page(base_address, address) then 1 else 2
    PC = address
end
]],
	CLC = [[
C = false
]],
	CLD = [[
D = false
]],
	CLI = [[
I = false
]],
	CLV = [[
V = false
]],
	SEC = [[
C = true
]],
	SED = [[
D = true
]],
	SEI = [[
I = true
]],
	SMB = [[
local result = bit32.replace(value, 1, bit_offset)
write(address, result)
]],
	RMB = [[
local result = bit32.replace(value, 0, bit_offset)
write(address, result)
]],
	BBS = [[
if bit32.extract(value, bit_offset) == 1 then
    cycles_taken += if same_page(base_address, address) then 1 else 2
    PC = address
end
]],
	BBR = [[
if bit32.extract(value, bit_offset) == 0 then
    cycles_taken += if same_page(base_address, address) then 1 else 2
    PC = address
end
]],
	WAI = [[
self._waiting = true
break
]],
	STP = [[
self._stopped = true
break
]],
	NOP = "",
}

local implementations = {}

for _, instruction: Wdc65c02.InstructionInfo in Wdc65c02.INSTRUCTIONS do
	local impl = ""

	local mode = MODES[instruction.mode] or error(`no mode impl for {instruction.mode}`)
	local op = OPS[instruction.mnemonic]
	if not op then
		implementations[instruction.opcode] = 'error("not implemented")'
		continue
	end

	if
		string.find(op, "value")
		and instruction.mode ~= "IMM"
		and instruction.mode ~= "IMP"
		and instruction.mode ~= "ACC"
		and instruction.mode:find("ZPR") == nil
	then
		op = "local value = read(address)\n" .. op
	end

	if instruction.mode == "ACC" then
		op = op:gsub("read%(address%)", "A")
		op = op:gsub("write%(address%s*,%s*(.-)%)", "A = %1")
	end

	if not COMPACT then
		impl ..= `--[[ {instruction.mnemonic}_{instruction.mode} ]]\n`
	end
	impl ..= `cycles_taken += {instruction.base_cycles}\n`
	impl ..= mode
	impl ..= op

	implementations[instruction.opcode] = impl
end

local function indent_str(str: string, level: number): string
	local spaces = string.rep(" ", level * 4)
	return spaces .. str:gsub("\n", "\n" .. spaces)
end

local out = ""
if BINARY_SEARCH then
	local function generate_tree(low: number, high: number, indent: number): string
		local tabs = string.rep("    ", indent)

		if low == high then
			return indent_str(implementations[low], indent) .. "\n"
		else
			local mid = math.floor((low + high) / 2)
			local out = ""

			out ..= string.format("%sif op <= %d then\n", tabs, mid)
			out ..= generate_tree(low, mid, indent + 1)
			out ..= string.format("%selse\n", tabs)
			out ..= generate_tree(mid + 1, high, indent + 1)
			out ..= string.format("%send\n", tabs)

			return out
		end
	end

	out = generate_tree(0, 255, 0)
else
	for i = 0, 255 do
		if i == 0 then
			out ..= "if "
		else
			out ..= "elseif "
		end

		local impl = indent_str(implementations[i], 1)

		local hex = string.format("%02X", i)
		out ..= `op == 0x{hex} then\n`
		out ..= impl
		out ..= "\n"
	end
	out ..= 'else\n    error("worm")\nend'
end

if COMPACT then
	out = out:gsub("\n", " "):gsub("%s%s*", " ")
end
out = "--stylua: ignore\n" .. out
zune.io.stdout:write(out)
