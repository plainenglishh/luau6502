--!nolint LocalShadow
--!nolint LocalUnused
--!nolint SameLineStatement
--!native
local opcodes = require("@self/opcodes")

type u8 = number
type u16 = number

export type Wdc65C02Snapshot = {
	a: u8,
	x: u8,
	y: u8,
	s: u8,
	p: u8,
	pc: u16,
}

export type ReadFn = (address: u16) -> u8
export type WriteFn = (address: u16, value: u8) -> ()
export type Memory = {
	read: ReadFn,
	write: WriteFn,
}

export type InstructionMode =
	| "IMP" -- Implied
	| "ACC" -- Accumulator                  A
	| "IMM" -- Immediate                    #$nn
	| "ABS" -- Absolute                     $nnnn
	| "ABX" -- X-Indexed Absolute           $nnnn,X
	| "ABY" -- Y-Indexed Absolute           $nnnn,Y
	| "IND" -- Absolute Indirect            ($nnnn)
	| "IAX" -- Absolute X-Indexed Indirect  ($nnnn,X)
	| "ZP0" -- Zero Page                    $nn
	| "ZPX" -- X-Indexed Zero Page          $nn,X
	| "ZPY" -- Y-Indexed Zero Page          $nn,Y
	| "ZPI" -- Zero Page Indirect           ($nn)
	| "IZX" -- X-Indexed Zero Page Indirect ($nn,X)
	| "IZY" -- Zero Page Indirect Y-Indexed ($nn),Y
	| "REL" -- Relative                     $nnnn (PC-relative)
	| "ZPB0" -- Bit 0, Zero Page            $00
	| "ZPB1" -- Bit 1, Zero Page            $00
	| "ZPB2" -- Bit 2, Zero Page            $00
	| "ZPB3" -- Bit 3, Zero Page            $00
	| "ZPB4" -- Bit 4, Zero Page            $00
	| "ZPB5" -- Bit 5, Zero Page            $00
	| "ZPB6" -- Bit 6, Zero Page            $00
	| "ZPB7" -- Bit 7, Zero Page            $00
	| "ZPR0" -- Bit 0, Zero Page Relative   $00,$0000 (PC-relative)
	| "ZPR1" -- Bit 1, Zero Page Relative   $00,$0000 (PC-relative)
	| "ZPR2" -- Bit 2, Zero Page Relative   $00,$0000 (PC-relative)
	| "ZPR3" -- Bit 3, Zero Page Relative   $00,$0000 (PC-relative)
	| "ZPR4" -- Bit 4, Zero Page Relative   $00,$0000 (PC-relative)
	| "ZPR5" -- Bit 5, Zero Page Relative   $00,$0000 (PC-relative)
	| "ZPR6" -- Bit 6, Zero Page Relative   $00,$0000 (PC-relative)
	| "ZPR7" -- Bit 7, Zero Page Relative   $00,$0000 (PC-relative)

export type InstructionInfo = {
	opcode: number,
	mnemonic: string,
	mode: InstructionMode,
	base_cycles: number,
}

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

--- Sums two u8-sized `number`s, wrapping if needed.
local function add_u8(a: u8, b: u8): u8
	return bit32.band(a + b, 0xFF)
end

--- Subtracts two u8-sized `number`s, wrapping if needed.
local function sub_u8(a: u8, b: u8): u8
	return bit32.band(a - b, 0xFF)
end

local function concat_u16(lo: u8, hi: u8): u16
	return bit32.bor(bit32.lshift(hi, 8), lo)
end

--[=[
    Modern verison of the NMOS6502.
]=]
export type Wdc65C02 = setmetatable<
	{
		_a: u8,
		_x: u8,
		_y: u8,
		_s: u8,
		_pc: u16,

		-- Used to determine processor flags.
		_n: u8,
		_z: u8,
		_v: boolean,
		_d: boolean,
		_i: boolean,
		_c: boolean,

		_read: ReadFn,
		_write: WriteFn,

		_nmi: boolean,
		_reset: boolean,
		_irq: boolean,

		_waiting: boolean,
		_stopped: boolean,

		_cycles: number,
	},
	{
		__index: getmetatable<Wdc65C02>,

		INSTRUCTIONS: { InstructionInfo },

		--[=[
            Creates a new `Wdc65C02`.
        ]=]
		new: (memory: Memory) -> Wdc65C02,

		--[=[
            Steps the CPU `cycle` amount of cycles. 
            
            Returns the number of cycles taken, which can be a bit higher than
            the requested amoun
        ]=]
		step: (self: Wdc65C02, cycles: number?) -> number,

		--[=[
            Resets the CPU on the next instruction.
        ]=]
		reset: (self: Wdc65C02) -> (),

		--[=[
            Interrupts the CPU on the next instruction.

			Unlike NMI, IRQ is level-sensitive, meaning the CPU will continue
			to be interrupted until it is set to false again.
        ]=]
		irq: (self: Wdc65C02, enabled: boolean) -> (),

		--[=[
            Interrupts the CPU on the next instruction.
        ]=]
		nmi: (self: Wdc65C02) -> (),
	}
>

local Wdc65C02 = {}
Wdc65C02.__index = Wdc65C02
Wdc65C02.INSTRUCTIONS = INSTRUCTIONS

function Wdc65C02.new(memory: Memory): Wdc65C02
	return setmetatable({
		_a = 0,
		_x = 0,
		_y = 0,
		_s = 0,
		_pc = 0,

		_n = 0,
		_z = 0,
		_b = false,
		_v = false,
		_d = false,
		_i = false,
		_c = false,

		_read = memory.read,
		_write = memory.write,

		_nmi = false,
		_reset = true,
		_irq = false,

		_waiting = false,
		_stopped = false,

		_cycles = 0,
	}, Wdc65C02)
end

function Wdc65C02.step(self: Wdc65C02, cycle_budget: number?): number
	local cycle_budget = cycle_budget or 1

	local read = self._read
	local write = self._write

	local A: number, X: number, Y: number, S: number, PC: number = self._a, self._x, self._y, self._s, self._pc
	local N: number, Z: number, V: boolean, D: boolean, I: boolean, C: boolean =
		self._n, self._z, self._v, self._d, self._i, self._c
	local cycles = 0

	local function fetch(): u8
		local value = read(PC)
		PC += 1
		return value
	end

	local function push(value: number)
		write(0x0100 + S, value)
		S = sub_u8(S, 1)
	end

	local function pull(): number
		S = add_u8(S, 1)
		return read(0x0100 + S)
	end

	---	Returns the P.
	local function get_p(set_b: boolean?): number
		local P = 0
		P = bit32.replace(P, N >= 0x80 and 1 or 0, 7)
		P = bit32.replace(P, V and 1 or 0, 6)
		P = bit32.replace(P, 1, 5)
		P = bit32.replace(P, if set_b then 1 else 0, 4)
		P = bit32.replace(P, D and 1 or 0, 3)
		P = bit32.replace(P, I and 1 or 0, 2)
		P = bit32.replace(P, Z == 0 and 1 or 0, 1)
		P = bit32.replace(P, C and 1 or 0, 0)
		return P
	end

	local function set_p(P: number)
		N = if bit32.extract(P, 7) == 1 then 0x80 else 0
		V = bit32.extract(P, 6) == 1
		D = bit32.extract(P, 3) == 1
		I = bit32.extract(P, 2) == 1
		Z = if bit32.extract(P, 1) == 1 then 0 else 1
		C = bit32.extract(P, 0) == 1
	end

	local function handle_interrupt(vector: number, brk: boolean)
		push(bit32.rshift(PC, 8))
		push(bit32.band(PC, 0xFF))

		push(get_p(brk))

		I = true
		D = false
		PC = concat_u16(read(vector), read(vector + 1))
	end

	while true do
		PC = bit32.band(PC, 0xFFFF) -- Wrap PC

		if cycles >= cycle_budget then
			break
		end

		if self._waiting then
			if self._reset or self._nmi or self._irq then
				self._waiting = false
			else
				cycles = cycle_budget
				break
			end
		end

		if self._reset or self._nmi or (self._irq and not I) then
			if self._reset then
				self._reset = false
				self._stopped = false
				PC = concat_u16(read(0xFFFC), read(0xFFFD))
				cycles += 7
			elseif self._nmi then
				self._nmi = false
				handle_interrupt(0xFFFA, false)
			elseif self._irq then
				handle_interrupt(0xFFFE, false)
			end

			continue
		end

		local op = fetch()
		local should_break
		A, X, Y, S, PC, N, Z, V, D, I, C, cycles, should_break =
			opcodes[op](self, read, write, A, X, Y, S, PC, N, Z, V, D, I, C, cycles)
		if should_break then
			break
		end
	end

	self._a, self._x, self._y, self._s, self._pc = A, X, Y, S, PC
	self._n, self._z, self._v, self._d, self._i, self._c = N, Z :: number, V, D, I, C
	self._cycles += cycles
	return cycles
end

function Wdc65C02.reset(self: Wdc65C02)
	self._reset = true
end

function Wdc65C02.irq(self: Wdc65C02, enabled: boolean)
	self._irq = enabled
end

function Wdc65C02.nmi(self: Wdc65C02)
	self._nmi = true
end

return Wdc65C02
