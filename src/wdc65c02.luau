--!nolint LocalShadow
--!native

--[=[
	TODO:
		- Determine our fundamental micro-ops, and implement them in `cycles`.
		- Populate the `ops` table with implemented micro-ops (consider 
		  automating?)
		- Use functional tests to help implement.
]=]
local _

local VECTOR_IRQB = 0xFFFE
local VECTOR_RESB = 0xFFFC
local VECTOR_NIMB = 0xFFFA
local STACK_BASE = 0x0100

local INSTRUCTIONS: { InstructionInfo } = {
	[0x7d] = { mnemonic = "ADC", opcode = 0x7d, mode = "ABX", base_cycles = 4 },
	[0x65] = { mnemonic = "ADC", opcode = 0x65, mode = "ZP0", base_cycles = 3 },
	[0x72] = { mnemonic = "ADC", opcode = 0x72, mode = "ZPI", base_cycles = 5 },
	[0x61] = { mnemonic = "ADC", opcode = 0x61, mode = "IZX", base_cycles = 6 },
	[0x6d] = { mnemonic = "ADC", opcode = 0x6d, mode = "ABS", base_cycles = 4 },
	[0x69] = { mnemonic = "ADC", opcode = 0x69, mode = "IMM", base_cycles = 2 },
	[0x71] = { mnemonic = "ADC", opcode = 0x71, mode = "IZY", base_cycles = 5 },
	[0x75] = { mnemonic = "ADC", opcode = 0x75, mode = "ZPX", base_cycles = 4 },
	[0x79] = { mnemonic = "ADC", opcode = 0x79, mode = "ABY", base_cycles = 4 },
	[0x21] = { mnemonic = "AND", opcode = 0x21, mode = "IZX", base_cycles = 6 },
	[0x39] = { mnemonic = "AND", opcode = 0x39, mode = "ABY", base_cycles = 4 },
	[0x25] = { mnemonic = "AND", opcode = 0x25, mode = "ZP0", base_cycles = 3 },
	[0x3d] = { mnemonic = "AND", opcode = 0x3d, mode = "ABX", base_cycles = 4 },
	[0x29] = { mnemonic = "AND", opcode = 0x29, mode = "IMM", base_cycles = 2 },
	[0x31] = { mnemonic = "AND", opcode = 0x31, mode = "IZY", base_cycles = 5 },
	[0x32] = { mnemonic = "AND", opcode = 0x32, mode = "ZPI", base_cycles = 5 },
	[0x35] = { mnemonic = "AND", opcode = 0x35, mode = "ZPX", base_cycles = 4 },
	[0x2d] = { mnemonic = "AND", opcode = 0x2d, mode = "ABS", base_cycles = 4 },
	[0x16] = { mnemonic = "ASL", opcode = 0x16, mode = "ZPX", base_cycles = 6 },
	[0x06] = { mnemonic = "ASL", opcode = 0x06, mode = "ZP0", base_cycles = 5 },
	[0x0a] = { mnemonic = "ASL", opcode = 0x0a, mode = "ACC", base_cycles = 2 },
	[0x1e] = { mnemonic = "ASL", opcode = 0x1e, mode = "ABX", base_cycles = 6 },
	[0x0e] = { mnemonic = "ASL", opcode = 0x0e, mode = "ABS", base_cycles = 6 },
	[0x3f] = { mnemonic = "BBR", opcode = 0x3f, mode = "ZPR3", base_cycles = 4 },
	[0x2f] = { mnemonic = "BBR", opcode = 0x2f, mode = "ZPR2", base_cycles = 4 },
	[0x1f] = { mnemonic = "BBR", opcode = 0x1f, mode = "ZPR1", base_cycles = 4 },
	[0x0f] = { mnemonic = "BBR", opcode = 0x0f, mode = "ZPR0", base_cycles = 4 },
	[0x7f] = { mnemonic = "BBR", opcode = 0x7f, mode = "ZPR7", base_cycles = 4 },
	[0x6f] = { mnemonic = "BBR", opcode = 0x6f, mode = "ZPR6", base_cycles = 4 },
	[0x5f] = { mnemonic = "BBR", opcode = 0x5f, mode = "ZPR5", base_cycles = 4 },
	[0x4f] = { mnemonic = "BBR", opcode = 0x4f, mode = "ZPR4", base_cycles = 4 },
	[0xdf] = { mnemonic = "BBS", opcode = 0xdf, mode = "ZPR5", base_cycles = 4 },
	[0xef] = { mnemonic = "BBS", opcode = 0xef, mode = "ZPR6", base_cycles = 4 },
	[0x8f] = { mnemonic = "BBS", opcode = 0x8f, mode = "ZPR0", base_cycles = 4 },
	[0x9f] = { mnemonic = "BBS", opcode = 0x9f, mode = "ZPR1", base_cycles = 4 },
	[0xff] = { mnemonic = "BBS", opcode = 0xff, mode = "ZPR7", base_cycles = 4 },
	[0xaf] = { mnemonic = "BBS", opcode = 0xaf, mode = "ZPR2", base_cycles = 4 },
	[0xbf] = { mnemonic = "BBS", opcode = 0xbf, mode = "ZPR3", base_cycles = 4 },
	[0xcf] = { mnemonic = "BBS", opcode = 0xcf, mode = "ZPR4", base_cycles = 4 },
	[0x90] = { mnemonic = "BCC", opcode = 0x90, mode = "REL", base_cycles = 2 },
	[0xb0] = { mnemonic = "BCS", opcode = 0xb0, mode = "REL", base_cycles = 2 },
	[0xf0] = { mnemonic = "BEQ", opcode = 0xf0, mode = "REL", base_cycles = 2 },
	[0x3c] = { mnemonic = "BIT", opcode = 0x3c, mode = "ABX", base_cycles = 4 },
	[0x34] = { mnemonic = "BIT", opcode = 0x34, mode = "ZPX", base_cycles = 4 },
	[0x24] = { mnemonic = "BIT", opcode = 0x24, mode = "ZP0", base_cycles = 3 },
	[0x89] = { mnemonic = "BIT", opcode = 0x89, mode = "IMM", base_cycles = 2 },
	[0x2c] = { mnemonic = "BIT", opcode = 0x2c, mode = "ABS", base_cycles = 4 },
	[0x30] = { mnemonic = "BMI", opcode = 0x30, mode = "REL", base_cycles = 2 },
	[0xd0] = { mnemonic = "BNE", opcode = 0xd0, mode = "REL", base_cycles = 2 },
	[0x10] = { mnemonic = "BPL", opcode = 0x10, mode = "REL", base_cycles = 2 },
	[0x80] = { mnemonic = "BRA", opcode = 0x80, mode = "REL", base_cycles = 3 },
	[0x00] = { mnemonic = "BRK", opcode = 0x00, mode = "IMP", base_cycles = 7 },
	[0x50] = { mnemonic = "BVC", opcode = 0x50, mode = "REL", base_cycles = 2 },
	[0x70] = { mnemonic = "BVS", opcode = 0x70, mode = "REL", base_cycles = 2 },
	[0x18] = { mnemonic = "CLC", opcode = 0x18, mode = "IMP", base_cycles = 2 },
	[0xd8] = { mnemonic = "CLD", opcode = 0xd8, mode = "IMP", base_cycles = 2 },
	[0x58] = { mnemonic = "CLI", opcode = 0x58, mode = "IMP", base_cycles = 2 },
	[0xb8] = { mnemonic = "CLV", opcode = 0xb8, mode = "IMP", base_cycles = 2 },
	[0xcd] = { mnemonic = "CMP", opcode = 0xcd, mode = "ABS", base_cycles = 4 },
	[0xc1] = { mnemonic = "CMP", opcode = 0xc1, mode = "IZX", base_cycles = 6 },
	[0xd2] = { mnemonic = "CMP", opcode = 0xd2, mode = "ZPI", base_cycles = 5 },
	[0xc9] = { mnemonic = "CMP", opcode = 0xc9, mode = "IMM", base_cycles = 2 },
	[0xd1] = { mnemonic = "CMP", opcode = 0xd1, mode = "IZY", base_cycles = 5 },
	[0xd9] = { mnemonic = "CMP", opcode = 0xd9, mode = "ABY", base_cycles = 4 },
	[0xdd] = { mnemonic = "CMP", opcode = 0xdd, mode = "ABX", base_cycles = 4 },
	[0xd5] = { mnemonic = "CMP", opcode = 0xd5, mode = "ZPX", base_cycles = 4 },
	[0xc5] = { mnemonic = "CMP", opcode = 0xc5, mode = "ZP0", base_cycles = 3 },
	[0xec] = { mnemonic = "CPX", opcode = 0xec, mode = "ABS", base_cycles = 4 },
	[0xe0] = { mnemonic = "CPX", opcode = 0xe0, mode = "IMM", base_cycles = 2 },
	[0xe4] = { mnemonic = "CPX", opcode = 0xe4, mode = "ZP0", base_cycles = 3 },
	[0xc4] = { mnemonic = "CPY", opcode = 0xc4, mode = "ZP0", base_cycles = 3 },
	[0xcc] = { mnemonic = "CPY", opcode = 0xcc, mode = "ABS", base_cycles = 4 },
	[0xc0] = { mnemonic = "CPY", opcode = 0xc0, mode = "IMM", base_cycles = 2 },
	[0x3a] = { mnemonic = "DEC", opcode = 0x3a, mode = "ACC", base_cycles = 2 },
	[0xd6] = { mnemonic = "DEC", opcode = 0xd6, mode = "ZPX", base_cycles = 6 },
	[0xde] = { mnemonic = "DEC", opcode = 0xde, mode = "ABX", base_cycles = 7 },
	[0xce] = { mnemonic = "DEC", opcode = 0xce, mode = "ABS", base_cycles = 6 },
	[0xc6] = { mnemonic = "DEC", opcode = 0xc6, mode = "ZP0", base_cycles = 5 },
	[0xca] = { mnemonic = "DEX", opcode = 0xca, mode = "IMP", base_cycles = 2 },
	[0x88] = { mnemonic = "DEY", opcode = 0x88, mode = "IMP", base_cycles = 2 },
	[0x5d] = { mnemonic = "EOR", opcode = 0x5d, mode = "ABX", base_cycles = 4 },
	[0x45] = { mnemonic = "EOR", opcode = 0x45, mode = "ZP0", base_cycles = 3 },
	[0x52] = { mnemonic = "EOR", opcode = 0x52, mode = "ZPI", base_cycles = 5 },
	[0x4d] = { mnemonic = "EOR", opcode = 0x4d, mode = "ABS", base_cycles = 4 },
	[0x49] = { mnemonic = "EOR", opcode = 0x49, mode = "IMM", base_cycles = 2 },
	[0x51] = { mnemonic = "EOR", opcode = 0x51, mode = "IZY", base_cycles = 5 },
	[0x55] = { mnemonic = "EOR", opcode = 0x55, mode = "ZPX", base_cycles = 4 },
	[0x41] = { mnemonic = "EOR", opcode = 0x41, mode = "IZX", base_cycles = 6 },
	[0x59] = { mnemonic = "EOR", opcode = 0x59, mode = "ABY", base_cycles = 4 },
	[0xe6] = { mnemonic = "INC", opcode = 0xe6, mode = "ZP0", base_cycles = 5 },
	[0xf6] = { mnemonic = "INC", opcode = 0xf6, mode = "ZPX", base_cycles = 6 },
	[0xfe] = { mnemonic = "INC", opcode = 0xfe, mode = "ABX", base_cycles = 7 },
	[0x1a] = { mnemonic = "INC", opcode = 0x1a, mode = "ACC", base_cycles = 2 },
	[0xee] = { mnemonic = "INC", opcode = 0xee, mode = "ABS", base_cycles = 6 },
	[0xe8] = { mnemonic = "INX", opcode = 0xe8, mode = "IMP", base_cycles = 2 },
	[0xc8] = { mnemonic = "INY", opcode = 0xc8, mode = "IMP", base_cycles = 2 },
	[0x6c] = { mnemonic = "JMP", opcode = 0x6c, mode = "IND", base_cycles = 6 },
	[0x7c] = { mnemonic = "JMP", opcode = 0x7c, mode = "ABX", base_cycles = 6 },
	[0x4c] = { mnemonic = "JMP", opcode = 0x4c, mode = "ABS", base_cycles = 3 },
	[0x20] = { mnemonic = "JSR", opcode = 0x20, mode = "ABS", base_cycles = 6 },
	[0xb5] = { mnemonic = "LDA", opcode = 0xb5, mode = "ZPX", base_cycles = 4 },
	[0xad] = { mnemonic = "LDA", opcode = 0xad, mode = "ABS", base_cycles = 4 },
	[0xb1] = { mnemonic = "LDA", opcode = 0xb1, mode = "IZY", base_cycles = 5 },
	[0xbd] = { mnemonic = "LDA", opcode = 0xbd, mode = "ABX", base_cycles = 4 },
	[0xa9] = { mnemonic = "LDA", opcode = 0xa9, mode = "IMM", base_cycles = 2 },
	[0xb2] = { mnemonic = "LDA", opcode = 0xb2, mode = "ZPI", base_cycles = 5 },
	[0xa1] = { mnemonic = "LDA", opcode = 0xa1, mode = "IZX", base_cycles = 6 },
	[0xb9] = { mnemonic = "LDA", opcode = 0xb9, mode = "ABY", base_cycles = 4 },
	[0xa5] = { mnemonic = "LDA", opcode = 0xa5, mode = "ZP0", base_cycles = 3 },
	[0xbe] = { mnemonic = "LDX", opcode = 0xbe, mode = "ABY", base_cycles = 4 },
	[0xa2] = { mnemonic = "LDX", opcode = 0xa2, mode = "IMM", base_cycles = 2 },
	[0xa6] = { mnemonic = "LDX", opcode = 0xa6, mode = "ZP0", base_cycles = 3 },
	[0xb6] = { mnemonic = "LDX", opcode = 0xb6, mode = "ZPY", base_cycles = 4 },
	[0xae] = { mnemonic = "LDX", opcode = 0xae, mode = "ABS", base_cycles = 4 },
	[0xb4] = { mnemonic = "LDY", opcode = 0xb4, mode = "ZPX", base_cycles = 4 },
	[0xa4] = { mnemonic = "LDY", opcode = 0xa4, mode = "ZP0", base_cycles = 3 },
	[0xa0] = { mnemonic = "LDY", opcode = 0xa0, mode = "IMM", base_cycles = 2 },
	[0xac] = { mnemonic = "LDY", opcode = 0xac, mode = "ABS", base_cycles = 4 },
	[0xbc] = { mnemonic = "LDY", opcode = 0xbc, mode = "ABX", base_cycles = 4 },
	[0x4a] = { mnemonic = "LSR", opcode = 0x4a, mode = "ACC", base_cycles = 2 },
	[0x4e] = { mnemonic = "LSR", opcode = 0x4e, mode = "ABS", base_cycles = 6 },
	[0x5e] = { mnemonic = "LSR", opcode = 0x5e, mode = "ABX", base_cycles = 6 },
	[0x46] = { mnemonic = "LSR", opcode = 0x46, mode = "ZP0", base_cycles = 5 },
	[0x56] = { mnemonic = "LSR", opcode = 0x56, mode = "ZPX", base_cycles = 6 },
	[0xea] = { mnemonic = "NOP", opcode = 0xea, mode = "IMP", base_cycles = 2 },
	[0x19] = { mnemonic = "ORA", opcode = 0x19, mode = "ABY", base_cycles = 4 },
	[0x01] = { mnemonic = "ORA", opcode = 0x01, mode = "IZX", base_cycles = 6 },
	[0x1d] = { mnemonic = "ORA", opcode = 0x1d, mode = "ABX", base_cycles = 4 },
	[0x05] = { mnemonic = "ORA", opcode = 0x05, mode = "ZP0", base_cycles = 3 },
	[0x11] = { mnemonic = "ORA", opcode = 0x11, mode = "IZY", base_cycles = 5 },
	[0x09] = { mnemonic = "ORA", opcode = 0x09, mode = "IMM", base_cycles = 2 },
	[0x0d] = { mnemonic = "ORA", opcode = 0x0d, mode = "ABS", base_cycles = 4 },
	[0x12] = { mnemonic = "ORA", opcode = 0x12, mode = "ZPI", base_cycles = 5 },
	[0x15] = { mnemonic = "ORA", opcode = 0x15, mode = "ZPX", base_cycles = 4 },
	[0x48] = { mnemonic = "PHA", opcode = 0x48, mode = "IMP", base_cycles = 3 },
	[0x08] = { mnemonic = "PHP", opcode = 0x08, mode = "IMP", base_cycles = 3 },
	[0xda] = { mnemonic = "PHX", opcode = 0xda, mode = "IMP", base_cycles = 3 },
	[0x5a] = { mnemonic = "PHY", opcode = 0x5a, mode = "IMP", base_cycles = 3 },
	[0x68] = { mnemonic = "PLA", opcode = 0x68, mode = "IMP", base_cycles = 4 },
	[0x28] = { mnemonic = "PLP", opcode = 0x28, mode = "IMP", base_cycles = 4 },
	[0xfa] = { mnemonic = "PLX", opcode = 0xfa, mode = "IMP", base_cycles = 4 },
	[0x7a] = { mnemonic = "PLY", opcode = 0x7a, mode = "IMP", base_cycles = 4 },
	[0x17] = { mnemonic = "RMB", opcode = 0x17, mode = "ZPB1", base_cycles = 5 },
	[0x77] = { mnemonic = "RMB", opcode = 0x77, mode = "ZPB7", base_cycles = 5 },
	[0x67] = { mnemonic = "RMB", opcode = 0x67, mode = "ZPB6", base_cycles = 5 },
	[0x57] = { mnemonic = "RMB", opcode = 0x57, mode = "ZPB5", base_cycles = 5 },
	[0x47] = { mnemonic = "RMB", opcode = 0x47, mode = "ZPB4", base_cycles = 5 },
	[0x37] = { mnemonic = "RMB", opcode = 0x37, mode = "ZPB3", base_cycles = 5 },
	[0x27] = { mnemonic = "RMB", opcode = 0x27, mode = "ZPB2", base_cycles = 5 },
	[0x07] = { mnemonic = "RMB", opcode = 0x07, mode = "ZPB0", base_cycles = 5 },
	[0x36] = { mnemonic = "ROL", opcode = 0x36, mode = "ZPX", base_cycles = 6 },
	[0x26] = { mnemonic = "ROL", opcode = 0x26, mode = "ZP0", base_cycles = 5 },
	[0x3e] = { mnemonic = "ROL", opcode = 0x3e, mode = "ABX", base_cycles = 6 },
	[0x2e] = { mnemonic = "ROL", opcode = 0x2e, mode = "ABS", base_cycles = 6 },
	[0x2a] = { mnemonic = "ROL", opcode = 0x2a, mode = "ACC", base_cycles = 2 },
	[0x6a] = { mnemonic = "ROR", opcode = 0x6a, mode = "ACC", base_cycles = 2 },
	[0x66] = { mnemonic = "ROR", opcode = 0x66, mode = "ZP0", base_cycles = 5 },
	[0x76] = { mnemonic = "ROR", opcode = 0x76, mode = "ZPX", base_cycles = 6 },
	[0x6e] = { mnemonic = "ROR", opcode = 0x6e, mode = "ABS", base_cycles = 6 },
	[0x7e] = { mnemonic = "ROR", opcode = 0x7e, mode = "ABX", base_cycles = 6 },
	[0x40] = { mnemonic = "RTI", opcode = 0x40, mode = "IMP", base_cycles = 6 },
	[0x60] = { mnemonic = "RTS", opcode = 0x60, mode = "IMP", base_cycles = 6 },
	[0xe1] = { mnemonic = "SBC", opcode = 0xe1, mode = "IZX", base_cycles = 6 },
	[0xf2] = { mnemonic = "SBC", opcode = 0xf2, mode = "ZPI", base_cycles = 5 },
	[0xe5] = { mnemonic = "SBC", opcode = 0xe5, mode = "ZP0", base_cycles = 3 },
	[0xf1] = { mnemonic = "SBC", opcode = 0xf1, mode = "IZY", base_cycles = 5 },
	[0xf9] = { mnemonic = "SBC", opcode = 0xf9, mode = "ABY", base_cycles = 4 },
	[0xf5] = { mnemonic = "SBC", opcode = 0xf5, mode = "ZPX", base_cycles = 4 },
	[0xfd] = { mnemonic = "SBC", opcode = 0xfd, mode = "ABX", base_cycles = 4 },
	[0xe9] = { mnemonic = "SBC", opcode = 0xe9, mode = "IMM", base_cycles = 2 },
	[0xed] = { mnemonic = "SBC", opcode = 0xed, mode = "ABS", base_cycles = 4 },
	[0x38] = { mnemonic = "SEC", opcode = 0x38, mode = "IMP", base_cycles = 2 },
	[0xf8] = { mnemonic = "SED", opcode = 0xf8, mode = "IMP", base_cycles = 2 },
	[0x78] = { mnemonic = "SEI", opcode = 0x78, mode = "IMP", base_cycles = 2 },
	[0x87] = { mnemonic = "SMB", opcode = 0x87, mode = "ZPB0", base_cycles = 5 },
	[0xf7] = { mnemonic = "SMB", opcode = 0xf7, mode = "ZPB7", base_cycles = 5 },
	[0xe7] = { mnemonic = "SMB", opcode = 0xe7, mode = "ZPB6", base_cycles = 5 },
	[0xd7] = { mnemonic = "SMB", opcode = 0xd7, mode = "ZPB5", base_cycles = 5 },
	[0xa7] = { mnemonic = "SMB", opcode = 0xa7, mode = "ZPB2", base_cycles = 5 },
	[0xb7] = { mnemonic = "SMB", opcode = 0xb7, mode = "ZPB3", base_cycles = 5 },
	[0xc7] = { mnemonic = "SMB", opcode = 0xc7, mode = "ZPB4", base_cycles = 5 },
	[0x97] = { mnemonic = "SMB", opcode = 0x97, mode = "ZPB1", base_cycles = 5 },
	[0x95] = { mnemonic = "STA", opcode = 0x95, mode = "ZPX", base_cycles = 5 },
	[0x85] = { mnemonic = "STA", opcode = 0x85, mode = "ZP0", base_cycles = 4 },
	[0x99] = { mnemonic = "STA", opcode = 0x99, mode = "ABY", base_cycles = 6 },
	[0x81] = { mnemonic = "STA", opcode = 0x81, mode = "IZX", base_cycles = 7 },
	[0x8d] = { mnemonic = "STA", opcode = 0x8d, mode = "ABS", base_cycles = 5 },
	[0x9d] = { mnemonic = "STA", opcode = 0x9d, mode = "ABX", base_cycles = 6 },
	[0x92] = { mnemonic = "STA", opcode = 0x92, mode = "ZPI", base_cycles = 6 },
	[0x91] = { mnemonic = "STA", opcode = 0x91, mode = "IZY", base_cycles = 7 },
	[0xdb] = { mnemonic = "STP", opcode = 0xdb, mode = "IMP", base_cycles = 2 },
	[0x8e] = { mnemonic = "STX", opcode = 0x8e, mode = "ABS", base_cycles = 5 },
	[0x86] = { mnemonic = "STX", opcode = 0x86, mode = "ZP0", base_cycles = 4 },
	[0x96] = { mnemonic = "STX", opcode = 0x96, mode = "ZPY", base_cycles = 5 },
	[0x84] = { mnemonic = "STY", opcode = 0x84, mode = "ZP0", base_cycles = 4 },
	[0x94] = { mnemonic = "STY", opcode = 0x94, mode = "ZPX", base_cycles = 5 },
	[0x8c] = { mnemonic = "STY", opcode = 0x8c, mode = "ABS", base_cycles = 5 },
	[0x9e] = { mnemonic = "STZ", opcode = 0x9e, mode = "ABX", base_cycles = 6 },
	[0x9c] = { mnemonic = "STZ", opcode = 0x9c, mode = "ABS", base_cycles = 5 },
	[0x64] = { mnemonic = "STZ", opcode = 0x64, mode = "ZP0", base_cycles = 4 },
	[0x74] = { mnemonic = "STZ", opcode = 0x74, mode = "ZPX", base_cycles = 5 },
	[0xaa] = { mnemonic = "TAX", opcode = 0xaa, mode = "IMP", base_cycles = 2 },
	[0xa8] = { mnemonic = "TAY", opcode = 0xa8, mode = "IMP", base_cycles = 2 },
	[0x14] = { mnemonic = "TRB", opcode = 0x14, mode = "ZP0", base_cycles = 5 },
	[0x1c] = { mnemonic = "TRB", opcode = 0x1c, mode = "ABS", base_cycles = 6 },
	[0x0c] = { mnemonic = "TSB", opcode = 0x0c, mode = "ABS", base_cycles = 6 },
	[0x04] = { mnemonic = "TSB", opcode = 0x04, mode = "ZP0", base_cycles = 5 },
	[0xba] = { mnemonic = "TSX", opcode = 0xba, mode = "IMP", base_cycles = 2 },
	[0x8a] = { mnemonic = "TXA", opcode = 0x8a, mode = "IMP", base_cycles = 2 },
	[0x9a] = { mnemonic = "TXS", opcode = 0x9a, mode = "IMP", base_cycles = 2 },
	[0x98] = { mnemonic = "TYA", opcode = 0x98, mode = "IMP", base_cycles = 2 },
	[0xcb] = { mnemonic = "WAI", opcode = 0xcb, mode = "IMP", base_cycles = 5 },
	[0x44] = { mnemonic = "NOP", opcode = 0x44, mode = "ZP0", base_cycles = 3 },
	[0x13] = { mnemonic = "NOP", opcode = 0x13, mode = "IMP", base_cycles = 1 },
	[0xbb] = { mnemonic = "NOP", opcode = 0xbb, mode = "IMP", base_cycles = 1 },
	[0x8b] = { mnemonic = "NOP", opcode = 0x8b, mode = "IMP", base_cycles = 1 },
	[0x6b] = { mnemonic = "NOP", opcode = 0x6b, mode = "IMP", base_cycles = 1 },
	[0x54] = { mnemonic = "NOP", opcode = 0x54, mode = "ZPX", base_cycles = 4 },
	[0x23] = { mnemonic = "NOP", opcode = 0x23, mode = "IMP", base_cycles = 1 },
	[0x2b] = { mnemonic = "NOP", opcode = 0x2b, mode = "IMP", base_cycles = 1 },
	[0xeb] = { mnemonic = "NOP", opcode = 0xeb, mode = "IMP", base_cycles = 1 },
	[0xd4] = { mnemonic = "NOP", opcode = 0xd4, mode = "ZPX", base_cycles = 4 },
	[0x5b] = { mnemonic = "NOP", opcode = 0x5b, mode = "IMP", base_cycles = 1 },
	[0x33] = { mnemonic = "NOP", opcode = 0x33, mode = "IMP", base_cycles = 1 },
	[0x1b] = { mnemonic = "NOP", opcode = 0x1b, mode = "IMP", base_cycles = 1 },
	[0x83] = { mnemonic = "NOP", opcode = 0x83, mode = "IMP", base_cycles = 1 },
	[0xd3] = { mnemonic = "NOP", opcode = 0xd3, mode = "IMP", base_cycles = 1 },
	[0x4b] = { mnemonic = "NOP", opcode = 0x4b, mode = "IMP", base_cycles = 1 },
	[0xc2] = { mnemonic = "NOP", opcode = 0xc2, mode = "IMM", base_cycles = 2 },
	[0x0b] = { mnemonic = "NOP", opcode = 0x0b, mode = "IMP", base_cycles = 1 },
	[0x63] = { mnemonic = "NOP", opcode = 0x63, mode = "IMP", base_cycles = 1 },
	[0x3b] = { mnemonic = "NOP", opcode = 0x3b, mode = "IMP", base_cycles = 1 },
	[0x02] = { mnemonic = "NOP", opcode = 0x02, mode = "IMM", base_cycles = 2 },
	[0xe3] = { mnemonic = "NOP", opcode = 0xe3, mode = "IMP", base_cycles = 1 },
	[0x53] = { mnemonic = "NOP", opcode = 0x53, mode = "IMP", base_cycles = 1 },
	[0x5c] = { mnemonic = "NOP", opcode = 0x5c, mode = "ABS", base_cycles = 8 },
	[0xdc] = { mnemonic = "NOP", opcode = 0xdc, mode = "ABX", base_cycles = 4 },
	[0x73] = { mnemonic = "NOP", opcode = 0x73, mode = "IMP", base_cycles = 1 },
	[0x93] = { mnemonic = "NOP", opcode = 0x93, mode = "IMP", base_cycles = 1 },
	[0xe2] = { mnemonic = "NOP", opcode = 0xe2, mode = "IMM", base_cycles = 2 },
	[0x82] = { mnemonic = "NOP", opcode = 0x82, mode = "IMM", base_cycles = 2 },
	[0x62] = { mnemonic = "NOP", opcode = 0x62, mode = "IMM", base_cycles = 2 },
	[0x42] = { mnemonic = "NOP", opcode = 0x42, mode = "IMM", base_cycles = 2 },
	[0xfc] = { mnemonic = "NOP", opcode = 0xfc, mode = "ABX", base_cycles = 4 },
	[0xfb] = { mnemonic = "NOP", opcode = 0xfb, mode = "IMP", base_cycles = 1 },
	[0xf3] = { mnemonic = "NOP", opcode = 0xf3, mode = "IMP", base_cycles = 1 },
	[0x22] = { mnemonic = "NOP", opcode = 0x22, mode = "IMM", base_cycles = 2 },
	[0xb3] = { mnemonic = "NOP", opcode = 0xb3, mode = "IMP", base_cycles = 1 },
	[0x03] = { mnemonic = "NOP", opcode = 0x03, mode = "IMP", base_cycles = 1 },
	[0xc3] = { mnemonic = "NOP", opcode = 0xc3, mode = "IMP", base_cycles = 1 },
	[0xab] = { mnemonic = "NOP", opcode = 0xab, mode = "IMP", base_cycles = 1 },
	[0xa3] = { mnemonic = "NOP", opcode = 0xa3, mode = "IMP", base_cycles = 1 },
	[0x9b] = { mnemonic = "NOP", opcode = 0x9b, mode = "IMP", base_cycles = 1 },
	[0xf4] = { mnemonic = "NOP", opcode = 0xf4, mode = "ZPX", base_cycles = 4 },
	[0x7b] = { mnemonic = "NOP", opcode = 0x7b, mode = "IMP", base_cycles = 1 },
	[0x43] = { mnemonic = "NOP", opcode = 0x43, mode = "IMP", base_cycles = 1 },
}

type u8 = number
type u16 = number

export type ErrorInfo = {
	type: "stack_overflow",
	snapshot: Wdc65c02,
}

export type ErrorHandler = (info: ErrorInfo) -> ()

--[=[
    The internal state and pinout of a WDC65C02S CPU.
]=]
export type Wdc65c02 = {
	-- Registers

	--[=[
		The **A**ccumulator register.
	]=]
	read a: u8,

	--[=[
		The **X** Index register.
	]=]
	read x: u8,

	--[=[
		The **Y** Index register.
	]=]
	read y: u8,

	--[=[
		The **S**tack Pointer register.

		Contains the current stack pointer. Grows downwards from `0xFF`, and 
		constitutes a memory address in the 0x0100-0x1FF stack page.
	]=]
	read s: u8,

	--[=[
		The **P**rogram **C**ounter register.

		Contains the program counter.
	]=]
	read pc: u16,

	--[=[
		The **I**nstruction **r**egister.

		Contains the currently-executing instruction.
	]=]
	read ir: u8,

	--[=[
		The **T**iming **C**ontrol **U**nit register.

		Contains the current cycle number for the current instruction.
	]=]
	read tcu: u8,

	--[=[
		The effective **Ad**ress low byte register.
	
		Contains the current in-use address low byte.
	]=]
	read _adl: u8,

	--[=[
		The effective **Ad**ress high byte register.

		Contains the current in-use address high byte.
	]=]
	read _adh: u8,

	-- Flags

	--[=[
		The **N**egative flag.

		Set if the last operation was negative (if bit 7 is set).
	]=]
	read n: boolean,

	--[=[
		The O**v**erflow flag.

		Set if the last operation overflowed.
	]=]
	read v: boolean,

	--[=[
		The **D**ecimal flag.

		When set, ALU instructions will perform BCD-decimal arithmetic.
	]=]
	read d: boolean,

	--[=[
		The **I**nterrupt disable flag.

		When set, maskable interrupts (BRK/IRQ) will be ignored.
	]=]
	read i: boolean,

	--[=[
		The **Z**ero flag.

		Set if the last operation was zero.
	]=]
	read z: boolean,

	--[=[
		The **C**arry flag.
	]=]
	read c: boolean,

	-- Pins

	--[=[
		The address bus (A0-A15) output pins.
	
		The address the CPU is currently trying to interact with.
	]=]
	read address_bus: u16,

	--[=[
		The data bus (D0-D7) input/output pins.

		The data the CPU has read (if rwb is high, or the data the CPU is
		trying to write (if rwb is low).
	]=]
	data_bus: u8,

	--[=[
		The **B**us **E**nable output pin.

		When high, indicates the CPU is attempting to interact with memory.
	]=]
	read be: boolean,

	--[=[
		The Interrupt Request (**IRQB**) input pin.

		When low, indicates the are interrupts the CPU must attend to.
	]=]
	irqb: boolean,

	--[=[
		The **M**emory **L**ock output pin
	
		When low, indicates the need to defer arbitration of the bus cycle.
	]=]
	read mlb: boolean,

	--[=[
		The **N**on-**M**askable **I**nterrupt input pin.

		Causes the CPU to initiate an interrupt sequence on transition from high
		to low.
	]=]
	nmib: boolean,

	--[=[
		The Phase 1 output pin.

		When high, indicates the CPU is currently in phase 1 of the current 
		cycle.
	]=]
	read phi1o: boolean,

	--[=[
		The Phase 2 output pin.

		When high, indicates the CPU is currently in phase 2 of the current 
		cycle.
	]=]
	read phi2o: boolean,

	--[=[
		The **R**ead **W**rite output pin.

		When high, indicates the CPU is attempting to read from memory / IO.
		When low, indicates the CPU is attempting to write to memory / IO.
	]=]
	read rwb: boolean,

	--[=[
		The **R**ea**dy** input/output pin.

		Will halt the CPU when low.
		
		Instructions like STP and WAI will pull this pin low internally.
	]=]
	rdy: boolean,

	--[=[
		The **Res**et input pin.

		When low (for at least two cycles), causes the CPU to reset.
	]=]
	resb: boolean,

	--[=[
		The **S**et **O**verflow input pin.

		Causes the internal overflow pin to be set when transitioning from high
		to low.
	]=]
	sob: boolean,

	--[=[
		The **Sync**hronise output pin.

		When high, indicates the CPU is currently fetching an opcode.
	]=]
	read sync: boolean,

	--[=[
		The **V**ector **P**ull output pin.

		When low, indicates an interrupt/vector pin is being addressed.
	]=]
	read vpb: boolean,

	-- Hooks
	on_error: ErrorHandler?,

	-- Other State
	read cycles: number, -- The number of cycles the CPU has used.
	read _pending_nmi: boolean,
	read _pending_irq: boolean,
	read _pending_resb: boolean,
	read _last_nmib: boolean, -- Edge detection (negative transition)
	read _last_sob: boolean, -- Edge detection (negative transiton)
	read _resb_downtime: number, -- Cycles RESB has been held low for
	read _last_resb: boolean, -- Edge detection (positive transition)
	read _internal_rdy: boolean, -- Internal RDY signal, to hold it low if outside tries to pull it high during WAI/STP
}

type function strip_read_only(t: type): type
	local props = {}

	for a, b in t:properties() do
		props[a] = b.read or b.write
	end

	return types.newtable(props)
end

type _Wdc65c02 = strip_read_only<Wdc65c02>

export type InstructionInfo = {
	mnemonic: string,
	opcode: number,
	mode: string,
	base_cycles: number,
}

type Uop = (cpu: _Wdc65c02, phi1: boolean) -> ()
type Op = { Uop }

-- Functions prefixed with uopaux are auxillary functions to be used in uop implementations.

local function uopaux_p1_push_value(cpu: _Wdc65c02, value: u8)
	cpu.address_bus = bit32.bor(STACK_BASE, cpu.s)
	cpu.s = (cpu.s - 1) % 0x100
	cpu.data_bus = value
	cpu.rwb = false
end

--- data will be available in phi2
local function uopaux_p1_read_value(cpu: _Wdc65c02, address: u16)
	cpu.address_bus = address
	cpu.rwb = true
end

local function uopaux_p2_load_bus_to_pc_low(cpu: _Wdc65c02)
	cpu.pc = bit32.replace(cpu.pc, cpu.data_bus, 0, 8)
end

local function uopaux_p2_load_bus_to_pc_high(cpu: _Wdc65c02)
	cpu.pc = bit32.replace(cpu.pc, cpu.data_bus, 8, 8)
end

--- Reusable uops/uop generators
local uops = {
	--- Fetch the opcode.
	fetch_op = function(cpu: _Wdc65c02, phi1: boolean)
		if phi1 then
			cpu.address_bus = cpu.pc
			cpu.rwb = true
		else
			cpu.ir = cpu.data_bus
			cpu.pc = (cpu.pc + 1) % 0x10000
		end
	end,

	--- Dummy read the PC.
	dummy_read_pc = function(cpu: _Wdc65c02, phi1: boolean)
		if phi1 then
			cpu.address_bus = cpu.pc
			cpu.rwb = true
		end
	end,

	reset = function(cpu: _Wdc65c02, phi1: boolean)
		if phi1 then
			cpu.d = false
			cpu.i = true
		end
	end,

	--- Push processor status.
	push_status = function(cpu: _Wdc65c02, phi1: boolean)
		if phi1 then
			uopaux_p1_push_value(cpu, 0)
		end
	end,

	push_return_address_low = function(cpu: _Wdc65c02, phi1: boolean)
		if phi1 then
			uopaux_p1_push_value(cpu, bit32.extract(cpu.pc + 1, 0, 8))
		end
	end,

	push_return_address_high = function(cpu: _Wdc65c02, phi1: boolean)
		if phi1 then
			uopaux_p1_push_value(cpu, bit32.extract(cpu.pc + 1, 8, 8))
		end
	end,

	jump_vector_low = function(vector: u16)
		return function(cpu: _Wdc65c02, phi1: boolean)
			if phi1 then
				uopaux_p1_read_value(cpu, vector)
				cpu.vpb = false
			else
				uopaux_p2_load_bus_to_pc_low(cpu)
			end
		end
	end,

	jump_vector_high = function(vector: u16)
		return function(cpu: _Wdc65c02, phi1: boolean)
			if phi1 then
				uopaux_p1_read_value(cpu, vector)
				cpu.vpb = false
			else
				uopaux_p2_load_bus_to_pc_high(cpu)
			end
		end
	end,
}

local ops: { [number]: Op } = table.create(256 + 3, nil :: any) -- extra used for reset/irq/nmi pseudoinstruction

--- RESET
ops[0xFF + 1] = {
	uops.dummy_read_pc,
	uops.reset,
	uops.dummy_read_pc, -- FIXME: stack
	uops.dummy_read_pc, -- FIXME: stack - 1
	uops.jump_vector_low(VECTOR_RESB),
	uops.jump_vector_high(VECTOR_RESB),
}

--- IRQ
ops[0xFF + 2] = {
	uops.dummy_read_pc,
	uops.push_return_address_high,
	uops.push_return_address_low,
	uops.push_status,
	uops.jump_vector_low(VECTOR_IRQB),
	uops.jump_vector_high(VECTOR_IRQB),
}

--- NMI
ops[0xFF + 3] = {
	uops.dummy_read_pc,
	uops.push_return_address_high,
	uops.push_return_address_low,
	uops.push_status,
	uops.jump_vector_low(VECTOR_NIMB),
	uops.jump_vector_high(VECTOR_NIMB),
}

local wdc65c02 = {}

wdc65c02.INSTRUCTIONS = INSTRUCTIONS

function wdc65c02.create(): Wdc65c02
	return {
		a = 0x00,
		x = 0x00,
		y = 0x00,
		s = 0xFF,
		pc = 0x0000,
		ir = 0x00,
		tcu = 1,
		_adl = 0,
		_adh = 0,

		n = false,
		v = false,
		d = false,
		i = true,
		z = false,
		c = false,

		address_bus = 0x0000,
		data_bus = 0x00,
		be = false,
		irqb = true,
		mlb = true,
		nmib = true,
		phi1o = true,
		phi2o = false,
		rwb = false,
		rdy = true,
		resb = true,
		sob = true,
		sync = false,
		vpb = true,

		on_error = nil,
		cycles = 0,
		_pending_nmi = false,
		_pending_irq = false,
		_pending_resb = true,
		_last_nmib = true,
		_last_sob = true,
		_resb_downtime = 0,
		_last_resb = true,
		_internal_rdy = true,
	}
end

--[=[
    Runs a single clock half-cycle.

    This is equivalent to inverting `PHI2`.
]=]
function wdc65c02.tick(cpu: Wdc65c02)
	local cpu = cpu :: _Wdc65c02

	local phi1 = cpu.phi2o
	local phi2 = cpu.phi1o
	cpu.phi1o = phi1
	cpu.phi2o = phi2

	if not cpu.rdy or not cpu._internal_rdy then
		cpu.rdy = false -- keep rdy low in the case of _internal_rdy

		-- TODO: handle STP/WAI

		if phi2 then
			cpu.cycles += 1
		end

		return
	end

	if phi2 then -- Tasks to do before PHI2
		cpu.be = false
		cpu.cycles += 1

		-- Check Reset
		if cpu.resb == true then
			if cpu._last_resb == false and cpu._resb_downtime >= 2 then
				cpu._pending_resb = true
			end
			cpu._resb_downtime = 0
		else
			cpu._resb_downtime += 1
		end

		-- Check NMI
		if cpu.nmib == false and cpu._last_nmib == true then
			cpu._pending_nmi = true
		end
		cpu._last_nmib = cpu.nmib

		-- Check IRQ
		cpu._pending_irq = (cpu.irqb == false) and not cpu.i

		-- Check SOB
		if cpu.sob == false and cpu._last_sob == true then
			cpu.v = true
		end
		cpu._last_sob = cpu.sob
	else
		cpu.be = true
	end

	local op = ops[cpu.ir]
	local uop = op[cpu.tcu]

	if uop then
		uop(cpu, phi1)
	else
		cpu.tcu = 0

		if cpu._pending_resb then
			cpu.ir = 0xFF + 1
		elseif cpu._pending_irq then
			cpu.ir = 0xFF + 2
		elseif cpu._pending_nmi then
			cpu.ir = 0xFF + 3
		else
			uops.fetch_op(cpu, phi1)
		end
	end

	cpu.tcu += 1
end

return wdc65c02
