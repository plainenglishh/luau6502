local raw_instructions = zune.serde.json.decode(
	zune.net.http.request(
		"https://raw.githubusercontent.com/ericTheEchidna/65C02-JSON/0289ecf15f16b1862d9d26b39ee5933473344408/opcodes_65c02.json"
	).body
)

local MODES = {
	["Immediate"] = "IMM",
	["Implied"] = "IMP",
	["Absolute, X"] = "ABX",
	["Absolute, Y"] = "ABY",
	["Zero Page"] = "ZP0",
	["Indirect"] = "IND",
	["(Indirect)"] = "ZPI",
	["(Indirect, X)"] = "IZX",
	["Absolute"] = "ABS",
	["(Indirect), Y"] = "IZY",
	["Zero Page, X"] = "ZPX",
	["Zero Page, Y"] = "ZPY",

	["Bit 0 - Zero Page, Relative"] = "ZPR0",
	["Bit 1 - Zero Page, Relative"] = "ZPR1",
	["Bit 2 - Zero Page, Relative"] = "ZPR2",
	["Bit 3 - Zero Page, Relative"] = "ZPR3",
	["Bit 4 - Zero Page, Relative"] = "ZPR4",
	["Bit 5 - Zero Page, Relative"] = "ZPR5",
	["Bit 6 - Zero Page, Relative"] = "ZPR6",
	["Bit 7 - Zero Page, Relative"] = "ZPR7",

	["Bit 0 - Zero Page"] = "ZPB0",
	["Bit 1 - Zero Page"] = "ZPB1",
	["Bit 2 - Zero Page"] = "ZPB2",
	["Bit 3 - Zero Page"] = "ZPB3",
	["Bit 4 - Zero Page"] = "ZPB4",
	["Bit 5 - Zero Page"] = "ZPB5",
	["Bit 6 - Zero Page"] = "ZPB6",
	["Bit 7 - Zero Page"] = "ZPB7",
}

local out = "local instructions: {InstructionInfo} = {\n"
for _, instruction in raw_instructions do
	for opcode: string, mode in instruction.opcodes do
		out ..= `    [{opcode}] = \{ `
		out ..= `mnemonic = "{if instruction.instruction == "UNP" then "NOP" else instruction.instruction}", `
		out ..= `opcode = {opcode}, `
		out ..= `mode = "{MODES[mode.address_mode] or print(opcode) or error(mode.address_mode)}", `
		out ..= `base_cycles = {mode.cycles:match("^(%d*)")} `
		out ..= "},\n"
	end
end
out ..= "}"
zune.io.stdout:write(out)
