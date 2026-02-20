local net = require("@lune/net")
local serde = require("@lune/serde")
local raw_instructions = serde.decode(
	"json",
	net.request(
		"https://gist.githubusercontent.com/benhess02/3873f6e5f305cd22ee5e1067d080c016/raw/a36248f9f5cc14304819b06e522d3e5fd6b6b57c/all_6502.json"
	).body
)

local instructions: { [string]: { any } } = {}
for _, insn in raw_instructions do
	if insn.mnemonics[1] == "USBC" then
		insn.mnemonics[1] = "SBC"
	end
	local name = insn.mnemonics[1]
	instructions[name] = instructions[name] or {}
	table.insert(instructions[name], insn)
end

local tbl: { string } = {}

local function write(str: string)
	table.insert(tbl, str)
end

local MODES = {
	implied = "IMP",
	accumulator = "ACC",
	immediate = "IMM",
	absolute = "ABS",
	absoluteX = "ABX",
	absoluteY = "ABY",
	indirect = "IND",
	zeropage = "ZP0",
	zeropageX = "ZPX",
	zeropageY = "ZPY",
	indirectX = "IZX",
	indirectY = "IZY",
	relative = "REL",
}

write("local instructions: {[number]: InstructionInfo} = {")

for name, group in instructions do
	write(`\n    -- {name}\n`)
	for _, instruction in group do
		write(string.format("    --[0x%02X] = {", instruction.opcode))
		write(string.format(" opcode = 0x%02X,", instruction.opcode))
		write(` mnemonic = "{instruction.mnemonics[1]}",`)
		write(` operation = ops.{instruction.mnemonics[1]},`)
		write(` mode = "{MODES[instruction.addressingMode or "implied"] or error(`{instruction.addressingMode}`)}",`)
		write(` cycles = {instruction.cycles or 0},`)
		write(` illegal = {instruction.illegal}`)
		write(` },\n`)
	end
end

write("}")

print(table.concat(tbl, ""))
