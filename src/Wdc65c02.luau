--!nolint LocalShadow
--!nolint LocalUnused
--!native

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

-- Table that tells the CPU how to offset into a page table entry.
export type Offsets = { [u8]: number? }
export type ReadMemory = { [u8]: buffer | ReadFn | nil }
export type WriteMemory = { [u8]: buffer | WriteFn | nil }
export type Memory = { read: ReadMemory, write: WriteMemory }
export type IntoMemory = buffer | Memory | { read: ReadFn, write: WriteFn }

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

--- Inline function to read from memory.
local function read_page_table(read_memory: ReadMemory, read_offsets: Offsets, address: u16): u8
	local page_idx = bit32.rshift(address, 8) + 1
	local page = read_memory[page_idx]
	local offset = read_offsets[page_idx]

	if offset then
		return buffer.readu8(page :: buffer, bit32.band(address, 0xFF) + offset)
	elseif page then
		return (page :: ReadFn)(address)
	else
		return 0
	end
end

--- Inline function to write to memory.
local function write_page_table(write_memory: WriteMemory, write_offsets: Offsets, address: u16, value: u8)
	local page_idx = bit32.rshift(address, 8) + 1
	local page = write_memory[page_idx]
	local offset = write_offsets[page_idx]

	if offset then
		buffer.writeu8(page :: buffer, bit32.band(address, 0xFF) + offset, value)
	elseif page then
		(page :: WriteFn)(address, value)
	end
end

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

		_read_memory: ReadMemory,
		_read_offsets: Offsets,
		_write_memory: WriteMemory,
		_write_offsets: Offsets,

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
		new: (memory: IntoMemory) -> Wdc65C02,

		--[=[
            Steps the CPU `cycle` amount of cycles. 
            
            Returns the number of cycles taken, which can be a bit higher than
            the requested amount.
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

function Wdc65C02.new(memory: IntoMemory): Wdc65C02
	local read_memory: ReadMemory, write_memory: WriteMemory
	local read_offsets: Offsets, write_offsets: Offsets = table.create(256, nil :: any), table.create(256, nil :: any)
	if type(memory) == "buffer" then
		read_memory = table.create(256) :: ReadMemory
		write_memory = table.create(256) :: WriteMemory

		for i = 1, 256 do
			read_memory[i] = memory
			write_memory[i] = memory
			read_offsets[i] = (i - 1) * 256
			write_offsets[i] = (i - 1) * 256
		end
	elseif type(memory.read) == "table" and type(memory.write) == "table" then
		read_memory = memory.read
		write_memory = memory.write

		for i = 1, 256 do
			read_offsets[i] = if type(read_memory[i]) == "buffer" then 0 else nil
			write_offsets[i] = if type(write_memory[i]) == "buffer" then 0 else nil
		end
	elseif type(memory.read) == "function" and type(memory.write) == "function" then
		read_memory = table.create(256, memory.read) :: ReadMemory
		write_memory = table.create(256, memory.write) :: WriteMemory
	else
		error("invalid memory")
	end

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

		_read_memory = read_memory,
		_read_offsets = read_offsets,
		_write_memory = write_memory,
		_write_offsets = write_offsets,

		_nmi = false,
		_reset = true,
		_irq = false,

		_waiting = false,
		_stopped = false,

		_cycles = 0,
	}, Wdc65C02)
end

function Wdc65C02.step(self: Wdc65C02, cycles: number?): number
	local cycles = cycles or 1
	local read_memory = self._read_memory
	local read_offsets = self._read_offsets
	local write_memory = self._write_memory
	local write_offsets = self._write_offsets

	local A, X, Y, S, PC = self._a, self._x, self._y, self._s, self._pc
	local N, Z, V, D, I, C = self._n, self._z, self._v, self._d, self._i, self._c
	local cycles_taken = 0

	local function read(address: u16): u8
		local value = read_page_table(read_memory, read_offsets, address)
		--print(string.format("reading 0x%04X: 0x%02X", address, value))
		return value
	end

	local function write(address: u16, value: u8)
		--print(string.format("writing 0x%02X to 0x%04X", value, address))
		return write_page_table(write_memory, write_offsets, address, value)
	end

	local function fetch(): u8
		local value = read(PC)
		PC += 1
		return value
	end

	local function push(value: number)
		write(0x0100 + S, value)
		S = SUB_U8(S, 1)
	end

	local function pull(): number
		S = ADD_U8(S, 1)
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
		--B = bit32.extract(P, 4) == 1
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
		PC = CONCAT_U16(read(vector), read(vector + 1))
	end

	while true do
		PC = bit32.band(PC, 0xFFFF) -- Wrap PC

		if cycles_taken >= cycles then
			break
		end

		if self._waiting then
			if self._reset or self._nmi or self._irq then
				self._waiting = false
			else
				cycles_taken = cycles
				break
			end
		end

		if self._reset or self._nmi or (self._irq and not I) then
			if self._reset then
				self._reset = false
				PC = CONCAT_U16(read(0xFFFC), read(0xFFFD))
				cycles_taken += 7
			elseif self._nmi then
				self._nmi = false
				handle_interrupt(0xFFFA, false)
			elseif self._irq then
				handle_interrupt(0xFFFE, false)
			end

			continue
		end

		local op = fetch()

		do -- OPCODE DISPATCH! OH MY GOODNESS
			if op == 0x00 then
				--[[ BRK_IMP ]]
				--
				cycles_taken += 7
				if self._irq and not I then
					continue -- back to start! cycles arent added
				end

				handle_interrupt(0xFFFE, true)
				cycles_taken -= 7 -- Horrible! but `handle_interrupt` cycles for us! It is what it is.
			elseif op == 0x01 then
				--[[ ORA_IZX ]]
				--
				cycles_taken += 6
				local ptr = ADD_U8(fetch(), X)
				local base_address = CONCAT_U16(read(ptr), read(ADD_U8(ptr, 1)))
				local address = base_address

				local value = read(address)
				A = bit32.bor(value, A)
				N, Z = A, A
			elseif op == 0x02 then
				--[[ NOP_IMM ]]
				--
				cycles_taken += 2
				local value = fetch()
				local address = nil
				local base_address = nil
			elseif op == 0x03 then
				--[[ NOP_IMP ]]
				--
				cycles_taken += 1
			elseif op == 0x04 then
				--[[ TSB_ZP0 ]]
				--
				cycles_taken += 5
				local base_address = fetch()
				local address = base_address
				local value = read(address)
				Z = bit32.band(A, value)
				local result = bit32.bor(A, value)
				write(address, result)
			elseif op == 0x05 then
				--[[ ORA_ZP0 ]]
				--
				cycles_taken += 3
				local base_address = fetch()
				local address = base_address
				local value = read(address)
				A = bit32.bor(value, A)
				N, Z = A, A
			elseif op == 0x06 then
				--[[ ASL_ZP0 ]]
				--
				cycles_taken += 5
				local base_address = fetch()
				local address = base_address
				local value = read(address)
				local result = bit32.lshift(value, 1)
				C = bit32.band(result, 0x100) ~= 0
				result = bit32.band(result, 0xFF)
				write(address, result)
				N, Z = result, result
			elseif op == 0x07 then
				--[[ RMB_ZPB0 ]]
				--
				cycles_taken += 5
				local address = fetch()
				local bit_offset = 0
				local value = read(address)
				local result = bit32.replace(value, 0, bit_offset)
				write(address, result)
			elseif op == 0x08 then
				--[[ PHP_IMP ]]
				--
				cycles_taken += 3
				push(bit32.bor(get_p(true), 0x30))
			elseif op == 0x09 then
				--[[ ORA_IMM ]]
				--
				cycles_taken += 2
				local value = fetch()
				local address = nil
				local base_address = nil
				A = bit32.bor(value, A)
				N, Z = A, A
			elseif op == 0x0A then
				--[[ ASL_ACC ]]
				--
				cycles_taken += 2
				local value = A
				local address = nil -- Macroed to A
				local base_address = nil -- Shouldn't be used.
				local result = bit32.lshift(value, 1)
				C = bit32.band(result, 0x100) ~= 0
				result = bit32.band(result, 0xFF)
				A = result
				N, Z = result, result
			elseif op == 0x0B then
				--[[ NOP_IMP ]]
				--
				cycles_taken += 1
			elseif op == 0x0C then
				--[[ TSB_ABS ]]
				--
				cycles_taken += 6
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = base_address
				local value = read(address)
				Z = bit32.band(A, value)
				local result = bit32.bor(A, value)
				write(address, result)
			elseif op == 0x0D then
				--[[ ORA_ABS ]]
				--
				cycles_taken += 4
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = base_address
				local value = read(address)
				A = bit32.bor(value, A)
				N, Z = A, A
			elseif op == 0x0E then
				--[[ ASL_ABS ]]
				--
				cycles_taken += 6
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = base_address
				local value = read(address)
				local result = bit32.lshift(value, 1)
				C = bit32.band(result, 0x100) ~= 0
				result = bit32.band(result, 0xFF)
				write(address, result)
				N, Z = result, result
			elseif op == 0x0F then
				--[[ BBR_ZPR0 ]]
				--
				cycles_taken += 4
				local zp_addr = fetch()
				local offset = fetch()
				local bit_offset = 0
				local rel = if offset > 127 then offset - 256 else offset

				local base_address = zp_addr
				local value = read(zp_addr) -- This is required for the bit test
				local address = ADD_U16(PC, rel) -- PC is now at the start of the next instruction
				if bit32.extract(value, bit_offset) == 0 then
					cycles_taken += if SAME_PAGE(base_address, address) then 1 else 2
					PC = address
				end
			elseif op == 0x10 then
				--[[ BPL_REL ]]
				--
				cycles_taken += 2
				local offset = REINTERPRET_SIGNED(fetch())
				local base_address = PC
				local address = ADD_U16(base_address, offset)
				-- extra cycles should be handled by the operation
				if N < 0x80 then
					cycles_taken += if SAME_PAGE(base_address, address) then 1 else 2
					PC = address
				end
			elseif op == 0x11 then
				--[[ ORA_IZY ]]
				--
				cycles_taken += 5
				local ptr = fetch()
				local base_address = CONCAT_U16(read(ptr), read(ADD_U8(ptr, 1)))
				local address = ADD_U16(base_address, Y)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				local value = read(address)
				A = bit32.bor(value, A)
				N, Z = A, A
			elseif op == 0x12 then
				--[[ ORA_ZPI ]]
				--
				cycles_taken += 5
				local ptr = fetch()
				local base_address = CONCAT_U16(read(ptr), read(ADD_U8(ptr, 1)))
				local address = base_address
				local value = read(address)
				A = bit32.bor(value, A)
				N, Z = A, A
			elseif op == 0x13 then
				--[[ NOP_IMP ]]
				--
				cycles_taken += 1
			elseif op == 0x14 then
				--[[ TRB_ZP0 ]]
				--
				cycles_taken += 5
				local base_address = fetch()
				local address = base_address
				local value = read(address)
				Z = bit32.band(A, value)
				local result = bit32.bor(value, A)
				write(address, result)
			elseif op == 0x15 then
				--[[ ORA_ZPX ]]
				--
				cycles_taken += 4
				local base_address = fetch()
				local address = ADD_U8(base_address, X)
				local value = read(address)
				A = bit32.bor(value, A)
				N, Z = A, A
			elseif op == 0x16 then
				--[[ ASL_ZPX ]]
				--
				cycles_taken += 6
				local base_address = fetch()
				local address = ADD_U8(base_address, X)
				local value = read(address)
				local result = bit32.lshift(value, 1)
				C = bit32.band(result, 0x100) ~= 0
				result = bit32.band(result, 0xFF)
				write(address, result)
				N, Z = result, result
			elseif op == 0x17 then
				--[[ RMB_ZPB1 ]]
				--
				cycles_taken += 5
				local address = fetch()
				local bit_offset = 1
				local value = read(address)
				local result = bit32.replace(value, 0, bit_offset)
				write(address, result)
			elseif op == 0x18 then
				--[[ CLC_IMP ]]
				--
				cycles_taken += 2
				C = false
			elseif op == 0x19 then
				--[[ ORA_ABY ]]
				--
				cycles_taken += 4
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = ADD_U16(base_address, Y)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				local value = read(address)
				A = bit32.bor(value, A)
				N, Z = A, A
			elseif op == 0x1A then
				--[[ INC_ACC ]]
				--
				cycles_taken += 2
				local value = A
				local address = nil -- Macroed to A
				local base_address = nil -- Shouldn't be used.
				local result = ADD_U8(value, 1)
				N, Z = result, result
				A = result
			elseif op == 0x1B then
				--[[ NOP_IMP ]]
				--
				cycles_taken += 1
			elseif op == 0x1C then
				--[[ TRB_ABS ]]
				--
				cycles_taken += 6
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = base_address
				local value = read(address)
				Z = bit32.band(A, value)
				local result = bit32.bor(value, A)
				write(address, result)
			elseif op == 0x1D then
				--[[ ORA_ABX ]]
				--
				cycles_taken += 4
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = ADD_U16(base_address, X)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				local value = read(address)
				A = bit32.bor(value, A)
				N, Z = A, A
			elseif op == 0x1E then
				--[[ ASL_ABX ]]
				--
				cycles_taken += 6
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = ADD_U16(base_address, X)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				local value = read(address)
				local result = bit32.lshift(value, 1)
				C = bit32.band(result, 0x100) ~= 0
				result = bit32.band(result, 0xFF)
				write(address, result)
				N, Z = result, result
			elseif op == 0x1F then
				--[[ BBR_ZPR1 ]]
				--
				cycles_taken += 4
				local zp_addr = fetch()
				local offset = fetch()
				local bit_offset = 1
				local rel = if offset > 127 then offset - 256 else offset

				local base_address = zp_addr
				local value = read(zp_addr) -- This is required for the bit test
				local address = ADD_U16(PC, rel) -- PC is now at the start of the next instruction
				if bit32.extract(value, bit_offset) == 0 then
					cycles_taken += if SAME_PAGE(base_address, address) then 1 else 2
					PC = address
				end
			elseif op == 0x20 then
				--[[ JSR_ABS ]]
				--
				cycles_taken += 6
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = base_address
				local return_address = SUB_U16(PC, 1)
				push(bit32.rshift(return_address, 8))
				push(bit32.band(return_address, 0xFF))
				PC = address
			elseif op == 0x21 then
				--[[ AND_IZX ]]
				--
				cycles_taken += 6
				local ptr = ADD_U8(fetch(), X)
				local base_address = CONCAT_U16(read(ptr), read(ADD_U8(ptr, 1)))
				local address = base_address

				local value = read(address)
				A = bit32.band(value, A)
				N, Z = A, A
			elseif op == 0x22 then
				--[[ NOP_IMM ]]
				--
				cycles_taken += 2
				local value = fetch()
				local address = nil
				local base_address = nil
			elseif op == 0x23 then
				--[[ NOP_IMP ]]
				--
				cycles_taken += 1
			elseif op == 0x24 then
				--[[ BIT_ZP0 ]]
				--
				cycles_taken += 3
				local base_address = fetch()
				local address = base_address
				local value = read(address)
				local res = bit32.band(A, value)
				Z = res

				if address then
					V = bit32.band(value, 0x40) ~= 0
					N = value
				end
			elseif op == 0x25 then
				--[[ AND_ZP0 ]]
				--
				cycles_taken += 3
				local base_address = fetch()
				local address = base_address
				local value = read(address)
				A = bit32.band(value, A)
				N, Z = A, A
			elseif op == 0x26 then
				--[[ ROL_ZP0 ]]
				--
				cycles_taken += 5
				local base_address = fetch()
				local address = base_address
				local value = read(address)
				local result = bit32.bor(bit32.lshift(value, 1), if C then 1 else 0)
				C = bit32.band(result, 0x100) ~= 0
				result = bit32.band(result, 0xFF)
				write(address, result)
				N, Z = result, result
			elseif op == 0x27 then
				--[[ RMB_ZPB2 ]]
				--
				cycles_taken += 5
				local address = fetch()
				local bit_offset = 2
				local value = read(address)
				local result = bit32.replace(value, 0, bit_offset)
				write(address, result)
			elseif op == 0x28 then
				--[[ PLP_IMP ]]
				--
				cycles_taken += 4
				set_p(pull())
			elseif op == 0x29 then
				--[[ AND_IMM ]]
				--
				cycles_taken += 2
				local value = fetch()
				local address = nil
				local base_address = nil
				A = bit32.band(value, A)
				N, Z = A, A
			elseif op == 0x2A then
				--[[ ROL_ACC ]]
				--
				cycles_taken += 2
				local value = A
				local address = nil -- Macroed to A
				local base_address = nil -- Shouldn't be used.
				local result = bit32.bor(bit32.lshift(value, 1), if C then 1 else 0)
				C = bit32.band(result, 0x100) ~= 0
				result = bit32.band(result, 0xFF)
				A = result
				N, Z = result, result
			elseif op == 0x2B then
				--[[ NOP_IMP ]]
				--
				cycles_taken += 1
			elseif op == 0x2C then
				--[[ BIT_ABS ]]
				--
				cycles_taken += 4
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = base_address
				local value = read(address)
				local res = bit32.band(A, value)
				Z = res

				if address then
					V = bit32.band(value, 0x40) ~= 0
					N = value
				end
			elseif op == 0x2D then
				--[[ AND_ABS ]]
				--
				cycles_taken += 4
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = base_address
				local value = read(address)
				A = bit32.band(value, A)
				N, Z = A, A
			elseif op == 0x2E then
				--[[ ROL_ABS ]]
				--
				cycles_taken += 6
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = base_address
				local value = read(address)
				local result = bit32.bor(bit32.lshift(value, 1), if C then 1 else 0)
				C = bit32.band(result, 0x100) ~= 0
				result = bit32.band(result, 0xFF)
				write(address, result)
				N, Z = result, result
			elseif op == 0x2F then
				--[[ BBR_ZPR2 ]]
				--
				cycles_taken += 4
				local zp_addr = fetch()
				local offset = fetch()
				local bit_offset = 2
				local rel = if offset > 127 then offset - 256 else offset

				local base_address = zp_addr
				local value = read(zp_addr) -- This is required for the bit test
				local address = ADD_U16(PC, rel) -- PC is now at the start of the next instruction
				if bit32.extract(value, bit_offset) == 0 then
					cycles_taken += if SAME_PAGE(base_address, address) then 1 else 2
					PC = address
				end
			elseif op == 0x30 then
				--[[ BMI_REL ]]
				--
				cycles_taken += 2
				local offset = REINTERPRET_SIGNED(fetch())
				local base_address = PC
				local address = ADD_U16(base_address, offset)
				-- extra cycles should be handled by the operation
				if N >= 0x80 then
					cycles_taken += if SAME_PAGE(base_address, address) then 1 else 2
					PC = address
				end
			elseif op == 0x31 then
				--[[ AND_IZY ]]
				--
				cycles_taken += 5
				local ptr = fetch()
				local base_address = CONCAT_U16(read(ptr), read(ADD_U8(ptr, 1)))
				local address = ADD_U16(base_address, Y)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				local value = read(address)
				A = bit32.band(value, A)
				N, Z = A, A
			elseif op == 0x32 then
				--[[ AND_ZPI ]]
				--
				cycles_taken += 5
				local ptr = fetch()
				local base_address = CONCAT_U16(read(ptr), read(ADD_U8(ptr, 1)))
				local address = base_address
				local value = read(address)
				A = bit32.band(value, A)
				N, Z = A, A
			elseif op == 0x33 then
				--[[ NOP_IMP ]]
				--
				cycles_taken += 1
			elseif op == 0x34 then
				--[[ BIT_ZPX ]]
				--
				cycles_taken += 4
				local base_address = fetch()
				local address = ADD_U8(base_address, X)
				local value = read(address)
				local res = bit32.band(A, value)
				Z = res

				if address then
					V = bit32.band(value, 0x40) ~= 0
					N = value
				end
			elseif op == 0x35 then
				--[[ AND_ZPX ]]
				--
				cycles_taken += 4
				local base_address = fetch()
				local address = ADD_U8(base_address, X)
				local value = read(address)
				A = bit32.band(value, A)
				N, Z = A, A
			elseif op == 0x36 then
				--[[ ROL_ZPX ]]
				--
				cycles_taken += 6
				local base_address = fetch()
				local address = ADD_U8(base_address, X)
				local value = read(address)
				local result = bit32.bor(bit32.lshift(value, 1), if C then 1 else 0)
				C = bit32.band(result, 0x100) ~= 0
				result = bit32.band(result, 0xFF)
				write(address, result)
				N, Z = result, result
			elseif op == 0x37 then
				--[[ RMB_ZPB3 ]]
				--
				cycles_taken += 5
				local address = fetch()
				local bit_offset = 3
				local value = read(address)
				local result = bit32.replace(value, 0, bit_offset)
				write(address, result)
			elseif op == 0x38 then
				--[[ SEC_IMP ]]
				--
				cycles_taken += 2
				C = true
			elseif op == 0x39 then
				--[[ AND_ABY ]]
				--
				cycles_taken += 4
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = ADD_U16(base_address, Y)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				local value = read(address)
				A = bit32.band(value, A)
				N, Z = A, A
			elseif op == 0x3A then
				--[[ DEC_ACC ]]
				--
				cycles_taken += 2
				local value = A
				local address = nil -- Macroed to A
				local base_address = nil -- Shouldn't be used.
				local result = SUB_U8(value, 1)
				N, Z = result, result
				A = result
			elseif op == 0x3B then
				--[[ NOP_IMP ]]
				--
				cycles_taken += 1
			elseif op == 0x3C then
				--[[ BIT_ABX ]]
				--
				cycles_taken += 4
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = ADD_U16(base_address, X)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				local value = read(address)
				local res = bit32.band(A, value)
				Z = res

				if address then
					V = bit32.band(value, 0x40) ~= 0
					N = value
				end
			elseif op == 0x3D then
				--[[ AND_ABX ]]
				--
				cycles_taken += 4
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = ADD_U16(base_address, X)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				local value = read(address)
				A = bit32.band(value, A)
				N, Z = A, A
			elseif op == 0x3E then
				--[[ ROL_ABX ]]
				--
				cycles_taken += 6
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = ADD_U16(base_address, X)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				local value = read(address)
				local result = bit32.bor(bit32.lshift(value, 1), if C then 1 else 0)
				C = bit32.band(result, 0x100) ~= 0
				result = bit32.band(result, 0xFF)
				write(address, result)
				N, Z = result, result
			elseif op == 0x3F then
				--[[ BBR_ZPR3 ]]
				--
				cycles_taken += 4
				local zp_addr = fetch()
				local offset = fetch()
				local bit_offset = 3
				local rel = if offset > 127 then offset - 256 else offset

				local base_address = zp_addr
				local value = read(zp_addr) -- This is required for the bit test
				local address = ADD_U16(PC, rel) -- PC is now at the start of the next instruction
				if bit32.extract(value, bit_offset) == 0 then
					cycles_taken += if SAME_PAGE(base_address, address) then 1 else 2
					PC = address
				end
			elseif op == 0x40 then
				--[[ RTI_IMP ]]
				--
				cycles_taken += 6
				set_p(pull())
				PC = CONCAT_U16(pull(), pull())
			elseif op == 0x41 then
				--[[ EOR_IZX ]]
				--
				cycles_taken += 6
				local ptr = ADD_U8(fetch(), X)
				local base_address = CONCAT_U16(read(ptr), read(ADD_U8(ptr, 1)))
				local address = base_address

				local value = read(address)
				A = bit32.bxor(value, A)
				N, Z = A, A
			elseif op == 0x42 then
				--[[ NOP_IMM ]]
				--
				cycles_taken += 2
				local value = fetch()
				local address = nil
				local base_address = nil
			elseif op == 0x43 then
				--[[ NOP_IMP ]]
				--
				cycles_taken += 1
			elseif op == 0x44 then
				--[[ NOP_ZP0 ]]
				--
				cycles_taken += 3
				local base_address = fetch()
				local address = base_address
			elseif op == 0x45 then
				--[[ EOR_ZP0 ]]
				--
				cycles_taken += 3
				local base_address = fetch()
				local address = base_address
				local value = read(address)
				A = bit32.bxor(value, A)
				N, Z = A, A
			elseif op == 0x46 then
				--[[ LSR_ZP0 ]]
				--
				cycles_taken += 5
				local base_address = fetch()
				local address = base_address
				local value = read(address)
				C = bit32.band(value, 0x01) ~= 0 -- Bit 0 goes into Carry
				local result = bit32.rshift(value, 1)
				write(address, result)
				N, Z = result, result
			elseif op == 0x47 then
				--[[ RMB_ZPB4 ]]
				--
				cycles_taken += 5
				local address = fetch()
				local bit_offset = 4
				local value = read(address)
				local result = bit32.replace(value, 0, bit_offset)
				write(address, result)
			elseif op == 0x48 then
				--[[ PHA_IMP ]]
				--
				cycles_taken += 3
				push(A)
			elseif op == 0x49 then
				--[[ EOR_IMM ]]
				--
				cycles_taken += 2
				local value = fetch()
				local address = nil
				local base_address = nil
				A = bit32.bxor(value, A)
				N, Z = A, A
			elseif op == 0x4A then
				--[[ LSR_ACC ]]
				--
				cycles_taken += 2
				local value = A
				local address = nil -- Macroed to A
				local base_address = nil -- Shouldn't be used.
				C = bit32.band(value, 0x01) ~= 0 -- Bit 0 goes into Carry
				local result = bit32.rshift(value, 1)
				A = result
				N, Z = result, result
			elseif op == 0x4B then
				--[[ NOP_IMP ]]
				--
				cycles_taken += 1
			elseif op == 0x4C then
				--[[ JMP_ABS ]]
				--
				cycles_taken += 3
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = base_address
				PC = address
			elseif op == 0x4D then
				--[[ EOR_ABS ]]
				--
				cycles_taken += 4
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = base_address
				local value = read(address)
				A = bit32.bxor(value, A)
				N, Z = A, A
			elseif op == 0x4E then
				--[[ LSR_ABS ]]
				--
				cycles_taken += 6
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = base_address
				local value = read(address)
				C = bit32.band(value, 0x01) ~= 0 -- Bit 0 goes into Carry
				local result = bit32.rshift(value, 1)
				write(address, result)
				N, Z = result, result
			elseif op == 0x4F then
				--[[ BBR_ZPR4 ]]
				--
				cycles_taken += 4
				local zp_addr = fetch()
				local offset = fetch()
				local bit_offset = 4
				local rel = if offset > 127 then offset - 256 else offset

				local base_address = zp_addr
				local value = read(zp_addr) -- This is required for the bit test
				local address = ADD_U16(PC, rel) -- PC is now at the start of the next instruction
				if bit32.extract(value, bit_offset) == 0 then
					cycles_taken += if SAME_PAGE(base_address, address) then 1 else 2
					PC = address
				end
			elseif op == 0x50 then
				--[[ BVC_REL ]]
				--
				cycles_taken += 2
				local offset = REINTERPRET_SIGNED(fetch())
				local base_address = PC
				local address = ADD_U16(base_address, offset)
				-- extra cycles should be handled by the operation
				if not V then
					cycles_taken += if SAME_PAGE(base_address, address) then 1 else 2
					PC = address
				end
			elseif op == 0x51 then
				--[[ EOR_IZY ]]
				--
				cycles_taken += 5
				local ptr = fetch()
				local base_address = CONCAT_U16(read(ptr), read(ADD_U8(ptr, 1)))
				local address = ADD_U16(base_address, Y)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				local value = read(address)
				A = bit32.bxor(value, A)
				N, Z = A, A
			elseif op == 0x52 then
				--[[ EOR_ZPI ]]
				--
				cycles_taken += 5
				local ptr = fetch()
				local base_address = CONCAT_U16(read(ptr), read(ADD_U8(ptr, 1)))
				local address = base_address
				local value = read(address)
				A = bit32.bxor(value, A)
				N, Z = A, A
			elseif op == 0x53 then
				--[[ NOP_IMP ]]
				--
				cycles_taken += 1
			elseif op == 0x54 then
				--[[ NOP_ZPX ]]
				--
				cycles_taken += 4
				local base_address = fetch()
				local address = ADD_U8(base_address, X)
			elseif op == 0x55 then
				--[[ EOR_ZPX ]]
				--
				cycles_taken += 4
				local base_address = fetch()
				local address = ADD_U8(base_address, X)
				local value = read(address)
				A = bit32.bxor(value, A)
				N, Z = A, A
			elseif op == 0x56 then
				--[[ LSR_ZPX ]]
				--
				cycles_taken += 6
				local base_address = fetch()
				local address = ADD_U8(base_address, X)
				local value = read(address)
				C = bit32.band(value, 0x01) ~= 0 -- Bit 0 goes into Carry
				local result = bit32.rshift(value, 1)
				write(address, result)
				N, Z = result, result
			elseif op == 0x57 then
				--[[ RMB_ZPB5 ]]
				--
				cycles_taken += 5
				local address = fetch()
				local bit_offset = 5
				local value = read(address)
				local result = bit32.replace(value, 0, bit_offset)
				write(address, result)
			elseif op == 0x58 then
				--[[ CLI_IMP ]]
				--
				cycles_taken += 2
				I = false
			elseif op == 0x59 then
				--[[ EOR_ABY ]]
				--
				cycles_taken += 4
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = ADD_U16(base_address, Y)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				local value = read(address)
				A = bit32.bxor(value, A)
				N, Z = A, A
			elseif op == 0x5A then
				--[[ PHY_IMP ]]
				--
				cycles_taken += 3
				push(Y)
			elseif op == 0x5B then
				--[[ NOP_IMP ]]
				--
				cycles_taken += 1
			elseif op == 0x5C then
				--[[ NOP_ABS ]]
				--
				cycles_taken += 8
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = base_address
			elseif op == 0x5D then
				--[[ EOR_ABX ]]
				--
				cycles_taken += 4
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = ADD_U16(base_address, X)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				local value = read(address)
				A = bit32.bxor(value, A)
				N, Z = A, A
			elseif op == 0x5E then
				--[[ LSR_ABX ]]
				--
				cycles_taken += 6
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = ADD_U16(base_address, X)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				local value = read(address)
				C = bit32.band(value, 0x01) ~= 0 -- Bit 0 goes into Carry
				local result = bit32.rshift(value, 1)
				write(address, result)
				N, Z = result, result
			elseif op == 0x5F then
				--[[ BBR_ZPR5 ]]
				--
				cycles_taken += 4
				local zp_addr = fetch()
				local offset = fetch()
				local bit_offset = 5
				local rel = if offset > 127 then offset - 256 else offset

				local base_address = zp_addr
				local value = read(zp_addr) -- This is required for the bit test
				local address = ADD_U16(PC, rel) -- PC is now at the start of the next instruction
				if bit32.extract(value, bit_offset) == 0 then
					cycles_taken += if SAME_PAGE(base_address, address) then 1 else 2
					PC = address
				end
			elseif op == 0x60 then
				--[[ RTS_IMP ]]
				--
				cycles_taken += 6
				PC = ADD_U16(CONCAT_U16(pull(), pull()), 1)
			elseif op == 0x61 then
				--[[ ADC_IZX ]]
				--
				cycles_taken += 6
				local ptr = ADD_U8(fetch(), X)
				local base_address = CONCAT_U16(read(ptr), read(ADD_U8(ptr, 1)))
				local address = base_address

				local value = read(address)
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

					if lo > 0x09 then
						lo += 0x06
						hi += 0x10
					end

					local binary_sum = A + value + (if C then 1 else 0)
					V = bit32.band(bit32.bxor(A, binary_sum), bit32.bxor(value, binary_sum), 0x80) ~= 0

					if hi > 0x90 then
						hi += 0x60
					end
					C = hi > 0xF0

					A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
					N, Z = A, A
				end
			elseif op == 0x62 then
				--[[ NOP_IMM ]]
				--
				cycles_taken += 2
				local value = fetch()
				local address = nil
				local base_address = nil
			elseif op == 0x63 then
				--[[ NOP_IMP ]]
				--
				cycles_taken += 1
			elseif op == 0x64 then
				--[[ STZ_ZP0 ]]
				--
				cycles_taken += 4
				local base_address = fetch()
				local address = base_address
				write(address, 0)
			elseif op == 0x65 then
				--[[ ADC_ZP0 ]]
				--
				cycles_taken += 3
				local base_address = fetch()
				local address = base_address
				local value = read(address)
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

					if lo > 0x09 then
						lo += 0x06
						hi += 0x10
					end

					local binary_sum = A + value + (if C then 1 else 0)
					V = bit32.band(bit32.bxor(A, binary_sum), bit32.bxor(value, binary_sum), 0x80) ~= 0

					if hi > 0x90 then
						hi += 0x60
					end
					C = hi > 0xF0

					A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
					N, Z = A, A
				end
			elseif op == 0x66 then
				--[[ ROR_ZP0 ]]
				--
				cycles_taken += 5
				local base_address = fetch()
				local address = base_address
				local value = read(address)
				local result = bit32.bor(bit32.rshift(value, 1), if C then 0x80 else 0)
				C = bit32.band(value, 0x01) ~= 0
				write(address, result)
				N, Z = result, result
			elseif op == 0x67 then
				--[[ RMB_ZPB6 ]]
				--
				cycles_taken += 5
				local address = fetch()
				local bit_offset = 6
				local value = read(address)
				local result = bit32.replace(value, 0, bit_offset)
				write(address, result)
			elseif op == 0x68 then
				--[[ PLA_IMP ]]
				--
				cycles_taken += 4
				A = pull()
				N, Z = A, A
			elseif op == 0x69 then
				--[[ ADC_IMM ]]
				--
				cycles_taken += 2
				local value = fetch()
				local address = nil
				local base_address = nil
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

					if lo > 0x09 then
						lo += 0x06
						hi += 0x10
					end

					local binary_sum = A + value + (if C then 1 else 0)
					V = bit32.band(bit32.bxor(A, binary_sum), bit32.bxor(value, binary_sum), 0x80) ~= 0

					if hi > 0x90 then
						hi += 0x60
					end
					C = hi > 0xF0

					A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
					N, Z = A, A
				end
			elseif op == 0x6A then
				--[[ ROR_ACC ]]
				--
				cycles_taken += 2
				local value = A
				local address = nil -- Macroed to A
				local base_address = nil -- Shouldn't be used.
				local result = bit32.bor(bit32.rshift(value, 1), if C then 0x80 else 0)
				C = bit32.band(value, 0x01) ~= 0
				A = result
				N, Z = result, result
			elseif op == 0x6B then
				--[[ NOP_IMP ]]
				--
				cycles_taken += 1
			elseif op == 0x6C then
				--[[ JMP_IND ]]
				--
				cycles_taken += 6
				local ptr = CONCAT_U16(fetch(), fetch())
				local base_address = CONCAT_U16(read(ptr), read(ADD_U16(ptr, 1)))
				local address = base_address
				PC = address
			elseif op == 0x6D then
				--[[ ADC_ABS ]]
				--
				cycles_taken += 4
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = base_address
				local value = read(address)
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

					if lo > 0x09 then
						lo += 0x06
						hi += 0x10
					end

					local binary_sum = A + value + (if C then 1 else 0)
					V = bit32.band(bit32.bxor(A, binary_sum), bit32.bxor(value, binary_sum), 0x80) ~= 0

					if hi > 0x90 then
						hi += 0x60
					end
					C = hi > 0xF0

					A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
					N, Z = A, A
				end
			elseif op == 0x6E then
				--[[ ROR_ABS ]]
				--
				cycles_taken += 6
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = base_address
				local value = read(address)
				local result = bit32.bor(bit32.rshift(value, 1), if C then 0x80 else 0)
				C = bit32.band(value, 0x01) ~= 0
				write(address, result)
				N, Z = result, result
			elseif op == 0x6F then
				--[[ BBR_ZPR6 ]]
				--
				cycles_taken += 4
				local zp_addr = fetch()
				local offset = fetch()
				local bit_offset = 6
				local rel = if offset > 127 then offset - 256 else offset

				local base_address = zp_addr
				local value = read(zp_addr) -- This is required for the bit test
				local address = ADD_U16(PC, rel) -- PC is now at the start of the next instruction
				if bit32.extract(value, bit_offset) == 0 then
					cycles_taken += if SAME_PAGE(base_address, address) then 1 else 2
					PC = address
				end
			elseif op == 0x70 then
				--[[ BVS_REL ]]
				--
				cycles_taken += 2
				local offset = REINTERPRET_SIGNED(fetch())
				local base_address = PC
				local address = ADD_U16(base_address, offset)
				-- extra cycles should be handled by the operation
				if V then
					cycles_taken += if SAME_PAGE(base_address, address) then 1 else 2
					PC = address
				end
			elseif op == 0x71 then
				--[[ ADC_IZY ]]
				--
				cycles_taken += 5
				local ptr = fetch()
				local base_address = CONCAT_U16(read(ptr), read(ADD_U8(ptr, 1)))
				local address = ADD_U16(base_address, Y)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				local value = read(address)
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

					if lo > 0x09 then
						lo += 0x06
						hi += 0x10
					end

					local binary_sum = A + value + (if C then 1 else 0)
					V = bit32.band(bit32.bxor(A, binary_sum), bit32.bxor(value, binary_sum), 0x80) ~= 0

					if hi > 0x90 then
						hi += 0x60
					end
					C = hi > 0xF0

					A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
					N, Z = A, A
				end
			elseif op == 0x72 then
				--[[ ADC_ZPI ]]
				--
				cycles_taken += 5
				local ptr = fetch()
				local base_address = CONCAT_U16(read(ptr), read(ADD_U8(ptr, 1)))
				local address = base_address
				local value = read(address)
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

					if lo > 0x09 then
						lo += 0x06
						hi += 0x10
					end

					local binary_sum = A + value + (if C then 1 else 0)
					V = bit32.band(bit32.bxor(A, binary_sum), bit32.bxor(value, binary_sum), 0x80) ~= 0

					if hi > 0x90 then
						hi += 0x60
					end
					C = hi > 0xF0

					A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
					N, Z = A, A
				end
			elseif op == 0x73 then
				--[[ NOP_IMP ]]
				--
				cycles_taken += 1
			elseif op == 0x74 then
				--[[ STZ_ZPX ]]
				--
				cycles_taken += 5
				local base_address = fetch()
				local address = ADD_U8(base_address, X)
				write(address, 0)
			elseif op == 0x75 then
				--[[ ADC_ZPX ]]
				--
				cycles_taken += 4
				local base_address = fetch()
				local address = ADD_U8(base_address, X)
				local value = read(address)
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

					if lo > 0x09 then
						lo += 0x06
						hi += 0x10
					end

					local binary_sum = A + value + (if C then 1 else 0)
					V = bit32.band(bit32.bxor(A, binary_sum), bit32.bxor(value, binary_sum), 0x80) ~= 0

					if hi > 0x90 then
						hi += 0x60
					end
					C = hi > 0xF0

					A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
					N, Z = A, A
				end
			elseif op == 0x76 then
				--[[ ROR_ZPX ]]
				--
				cycles_taken += 6
				local base_address = fetch()
				local address = ADD_U8(base_address, X)
				local value = read(address)
				local result = bit32.bor(bit32.rshift(value, 1), if C then 0x80 else 0)
				C = bit32.band(value, 0x01) ~= 0
				write(address, result)
				N, Z = result, result
			elseif op == 0x77 then
				--[[ RMB_ZPB7 ]]
				--
				cycles_taken += 5
				local address = fetch()
				local bit_offset = 7
				local value = read(address)
				local result = bit32.replace(value, 0, bit_offset)
				write(address, result)
			elseif op == 0x78 then
				--[[ SEI_IMP ]]
				--
				cycles_taken += 2
				I = true
			elseif op == 0x79 then
				--[[ ADC_ABY ]]
				--
				cycles_taken += 4
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = ADD_U16(base_address, Y)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				local value = read(address)
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

					if lo > 0x09 then
						lo += 0x06
						hi += 0x10
					end

					local binary_sum = A + value + (if C then 1 else 0)
					V = bit32.band(bit32.bxor(A, binary_sum), bit32.bxor(value, binary_sum), 0x80) ~= 0

					if hi > 0x90 then
						hi += 0x60
					end
					C = hi > 0xF0

					A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
					N, Z = A, A
				end
			elseif op == 0x7A then
				--[[ PLY_IMP ]]
				--
				cycles_taken += 4
				Y = pull()
				N, Z = Y, Y
			elseif op == 0x7B then
				--[[ NOP_IMP ]]
				--
				cycles_taken += 1
			elseif op == 0x7C then
				--[[ JMP_ABX ]]
				--
				cycles_taken += 6
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = ADD_U16(base_address, X)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				PC = address
			elseif op == 0x7D then
				--[[ ADC_ABX ]]
				--
				cycles_taken += 4
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = ADD_U16(base_address, X)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				local value = read(address)
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

					if lo > 0x09 then
						lo += 0x06
						hi += 0x10
					end

					local binary_sum = A + value + (if C then 1 else 0)
					V = bit32.band(bit32.bxor(A, binary_sum), bit32.bxor(value, binary_sum), 0x80) ~= 0

					if hi > 0x90 then
						hi += 0x60
					end
					C = hi > 0xF0

					A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
					N, Z = A, A
				end
			elseif op == 0x7E then
				--[[ ROR_ABX ]]
				--
				cycles_taken += 6
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = ADD_U16(base_address, X)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				local value = read(address)
				local result = bit32.bor(bit32.rshift(value, 1), if C then 0x80 else 0)
				C = bit32.band(value, 0x01) ~= 0
				write(address, result)
				N, Z = result, result
			elseif op == 0x7F then
				--[[ BBR_ZPR7 ]]
				--
				cycles_taken += 4
				local zp_addr = fetch()
				local offset = fetch()
				local bit_offset = 7
				local rel = if offset > 127 then offset - 256 else offset

				local base_address = zp_addr
				local value = read(zp_addr) -- This is required for the bit test
				local address = ADD_U16(PC, rel) -- PC is now at the start of the next instruction
				if bit32.extract(value, bit_offset) == 0 then
					cycles_taken += if SAME_PAGE(base_address, address) then 1 else 2
					PC = address
				end
			elseif op == 0x80 then
				--[[ BRA_REL ]]
				--
				cycles_taken += 3
				local offset = REINTERPRET_SIGNED(fetch())
				local base_address = PC
				local address = ADD_U16(base_address, offset)
				-- extra cycles should be handled by the operation
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				PC = address
			elseif op == 0x81 then
				--[[ STA_IZX ]]
				--
				cycles_taken += 7
				local ptr = ADD_U8(fetch(), X)
				local base_address = CONCAT_U16(read(ptr), read(ADD_U8(ptr, 1)))
				local address = base_address

				write(address, A)
			elseif op == 0x82 then
				--[[ NOP_IMM ]]
				--
				cycles_taken += 2
				local value = fetch()
				local address = nil
				local base_address = nil
			elseif op == 0x83 then
				--[[ NOP_IMP ]]
				--
				cycles_taken += 1
			elseif op == 0x84 then
				--[[ STY_ZP0 ]]
				--
				cycles_taken += 4
				local base_address = fetch()
				local address = base_address
				write(address, Y)
			elseif op == 0x85 then
				--[[ STA_ZP0 ]]
				--
				cycles_taken += 4
				local base_address = fetch()
				local address = base_address
				write(address, A)
			elseif op == 0x86 then
				--[[ STX_ZP0 ]]
				--
				cycles_taken += 4
				local base_address = fetch()
				local address = base_address
				write(address, X)
			elseif op == 0x87 then
				--[[ SMB_ZPB0 ]]
				--
				cycles_taken += 5
				local address = fetch()
				local bit_offset = 0
				local value = read(address)
				local result = bit32.replace(value, 1, bit_offset)
				write(address, result)
			elseif op == 0x88 then
				--[[ DEY_IMP ]]
				--
				cycles_taken += 2
				Y = SUB_U8(Y, 1)
				N, Z = Y, Y
			elseif op == 0x89 then
				--[[ BIT_IMM ]]
				--
				cycles_taken += 2
				local value = fetch()
				local address = nil
				local base_address = nil
				local res = bit32.band(A, value)
				Z = res

				if address then
					V = bit32.band(value, 0x40) ~= 0
					N = value
				end
			elseif op == 0x8A then
				--[[ TXA_IMP ]]
				--
				cycles_taken += 2
				A = X
				N, Z = A, A
			elseif op == 0x8B then
				--[[ NOP_IMP ]]
				--
				cycles_taken += 1
			elseif op == 0x8C then
				--[[ STY_ABS ]]
				--
				cycles_taken += 5
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = base_address
				write(address, Y)
			elseif op == 0x8D then
				--[[ STA_ABS ]]
				--
				cycles_taken += 5
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = base_address
				write(address, A)
			elseif op == 0x8E then
				--[[ STX_ABS ]]
				--
				cycles_taken += 5
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = base_address
				write(address, X)
			elseif op == 0x8F then
				--[[ BBS_ZPR0 ]]
				--
				cycles_taken += 4
				local zp_addr = fetch()
				local offset = fetch()
				local bit_offset = 0
				local rel = if offset > 127 then offset - 256 else offset

				local base_address = zp_addr
				local value = read(zp_addr) -- This is required for the bit test
				local address = ADD_U16(PC, rel) -- PC is now at the start of the next instruction
				if bit32.extract(value, bit_offset) == 1 then
					cycles_taken += if SAME_PAGE(base_address, address) then 1 else 2
					PC = address
				end
			elseif op == 0x90 then
				--[[ BCC_REL ]]
				--
				cycles_taken += 2
				local offset = REINTERPRET_SIGNED(fetch())
				local base_address = PC
				local address = ADD_U16(base_address, offset)
				-- extra cycles should be handled by the operation
				if not C then
					cycles_taken += if SAME_PAGE(base_address, address) then 1 else 2
					PC = address
				end
			elseif op == 0x91 then
				--[[ STA_IZY ]]
				--
				cycles_taken += 7
				local ptr = fetch()
				local base_address = CONCAT_U16(read(ptr), read(ADD_U8(ptr, 1)))
				local address = ADD_U16(base_address, Y)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				write(address, A)
			elseif op == 0x92 then
				--[[ STA_ZPI ]]
				--
				cycles_taken += 6
				local ptr = fetch()
				local base_address = CONCAT_U16(read(ptr), read(ADD_U8(ptr, 1)))
				local address = base_address
				write(address, A)
			elseif op == 0x93 then
				--[[ NOP_IMP ]]
				--
				cycles_taken += 1
			elseif op == 0x94 then
				--[[ STY_ZPX ]]
				--
				cycles_taken += 5
				local base_address = fetch()
				local address = ADD_U8(base_address, X)
				write(address, Y)
			elseif op == 0x95 then
				--[[ STA_ZPX ]]
				--
				cycles_taken += 5
				local base_address = fetch()
				local address = ADD_U8(base_address, X)
				write(address, A)
			elseif op == 0x96 then
				--[[ STX_ZPY ]]
				--
				cycles_taken += 5
				local base_address = fetch()
				local address = ADD_U8(base_address, Y)
				write(address, X)
			elseif op == 0x97 then
				--[[ SMB_ZPB1 ]]
				--
				cycles_taken += 5
				local address = fetch()
				local bit_offset = 1
				local value = read(address)
				local result = bit32.replace(value, 1, bit_offset)
				write(address, result)
			elseif op == 0x98 then
				--[[ TYA_IMP ]]
				--
				cycles_taken += 2
				A = Y
				N, Z = A, A
			elseif op == 0x99 then
				--[[ STA_ABY ]]
				--
				cycles_taken += 6
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = ADD_U16(base_address, Y)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				write(address, A)
			elseif op == 0x9A then
				--[[ TXS_IMP ]]
				--
				cycles_taken += 2
				S = X
				N, Z = S, S
			elseif op == 0x9B then
				--[[ NOP_IMP ]]
				--
				cycles_taken += 1
			elseif op == 0x9C then
				--[[ STZ_ABS ]]
				--
				cycles_taken += 5
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = base_address
				write(address, 0)
			elseif op == 0x9D then
				--[[ STA_ABX ]]
				--
				cycles_taken += 6
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = ADD_U16(base_address, X)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				write(address, A)
			elseif op == 0x9E then
				--[[ STZ_ABX ]]
				--
				cycles_taken += 6
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = ADD_U16(base_address, X)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				write(address, 0)
			elseif op == 0x9F then
				--[[ BBS_ZPR1 ]]
				--
				cycles_taken += 4
				local zp_addr = fetch()
				local offset = fetch()
				local bit_offset = 1
				local rel = if offset > 127 then offset - 256 else offset

				local base_address = zp_addr
				local value = read(zp_addr) -- This is required for the bit test
				local address = ADD_U16(PC, rel) -- PC is now at the start of the next instruction
				if bit32.extract(value, bit_offset) == 1 then
					cycles_taken += if SAME_PAGE(base_address, address) then 1 else 2
					PC = address
				end
			elseif op == 0xA0 then
				--[[ LDY_IMM ]]
				--
				cycles_taken += 2
				local value = fetch()
				local address = nil
				local base_address = nil
				Y = value
				N, Z = value, value
			elseif op == 0xA1 then
				--[[ LDA_IZX ]]
				--
				cycles_taken += 6
				local ptr = ADD_U8(fetch(), X)
				local base_address = CONCAT_U16(read(ptr), read(ADD_U8(ptr, 1)))
				local address = base_address

				local value = read(address)
				A = value
				N, Z = value, value
			elseif op == 0xA2 then
				--[[ LDX_IMM ]]
				--
				cycles_taken += 2
				local value = fetch()
				local address = nil
				local base_address = nil
				X = value
				N, Z = value, value
			elseif op == 0xA3 then
				--[[ NOP_IMP ]]
				--
				cycles_taken += 1
			elseif op == 0xA4 then
				--[[ LDY_ZP0 ]]
				--
				cycles_taken += 3
				local base_address = fetch()
				local address = base_address
				local value = read(address)
				Y = value
				N, Z = value, value
			elseif op == 0xA5 then
				--[[ LDA_ZP0 ]]
				--
				cycles_taken += 3
				local base_address = fetch()
				local address = base_address
				local value = read(address)
				A = value
				N, Z = value, value
			elseif op == 0xA6 then
				--[[ LDX_ZP0 ]]
				--
				cycles_taken += 3
				local base_address = fetch()
				local address = base_address
				local value = read(address)
				X = value
				N, Z = value, value
			elseif op == 0xA7 then
				--[[ SMB_ZPB2 ]]
				--
				cycles_taken += 5
				local address = fetch()
				local bit_offset = 2
				local value = read(address)
				local result = bit32.replace(value, 1, bit_offset)
				write(address, result)
			elseif op == 0xA8 then
				--[[ TAY_IMP ]]
				--
				cycles_taken += 2
				Y = A
				N, Z = Y, Y
			elseif op == 0xA9 then
				--[[ LDA_IMM ]]
				--
				cycles_taken += 2
				local value = fetch()
				local address = nil
				local base_address = nil
				A = value
				N, Z = value, value
			elseif op == 0xAA then
				--[[ TAX_IMP ]]
				--
				cycles_taken += 2
				X = A
				N, Z = X, X
			elseif op == 0xAB then
				--[[ NOP_IMP ]]
				--
				cycles_taken += 1
			elseif op == 0xAC then
				--[[ LDY_ABS ]]
				--
				cycles_taken += 4
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = base_address
				local value = read(address)
				Y = value
				N, Z = value, value
			elseif op == 0xAD then
				--[[ LDA_ABS ]]
				--
				cycles_taken += 4
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = base_address
				local value = read(address)
				A = value
				N, Z = value, value
			elseif op == 0xAE then
				--[[ LDX_ABS ]]
				--
				cycles_taken += 4
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = base_address
				local value = read(address)
				X = value
				N, Z = value, value
			elseif op == 0xAF then
				--[[ BBS_ZPR2 ]]
				--
				cycles_taken += 4
				local zp_addr = fetch()
				local offset = fetch()
				local bit_offset = 2
				local rel = if offset > 127 then offset - 256 else offset

				local base_address = zp_addr
				local value = read(zp_addr) -- This is required for the bit test
				local address = ADD_U16(PC, rel) -- PC is now at the start of the next instruction
				if bit32.extract(value, bit_offset) == 1 then
					cycles_taken += if SAME_PAGE(base_address, address) then 1 else 2
					PC = address
				end
			elseif op == 0xB0 then
				--[[ BCS_REL ]]
				--
				cycles_taken += 2
				local offset = REINTERPRET_SIGNED(fetch())
				local base_address = PC
				local address = ADD_U16(base_address, offset)
				-- extra cycles should be handled by the operation
				if C then
					cycles_taken += if SAME_PAGE(base_address, address) then 1 else 2
					PC = address
				end
			elseif op == 0xB1 then
				--[[ LDA_IZY ]]
				--
				cycles_taken += 5
				local ptr = fetch()
				local base_address = CONCAT_U16(read(ptr), read(ADD_U8(ptr, 1)))
				local address = ADD_U16(base_address, Y)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				local value = read(address)
				A = value
				N, Z = value, value
			elseif op == 0xB2 then
				--[[ LDA_ZPI ]]
				--
				cycles_taken += 5
				local ptr = fetch()
				local base_address = CONCAT_U16(read(ptr), read(ADD_U8(ptr, 1)))
				local address = base_address
				local value = read(address)
				A = value
				N, Z = value, value
			elseif op == 0xB3 then
				--[[ NOP_IMP ]]
				--
				cycles_taken += 1
			elseif op == 0xB4 then
				--[[ LDY_ZPX ]]
				--
				cycles_taken += 4
				local base_address = fetch()
				local address = ADD_U8(base_address, X)
				local value = read(address)
				Y = value
				N, Z = value, value
			elseif op == 0xB5 then
				--[[ LDA_ZPX ]]
				--
				cycles_taken += 4
				local base_address = fetch()
				local address = ADD_U8(base_address, X)
				local value = read(address)
				A = value
				N, Z = value, value
			elseif op == 0xB6 then
				--[[ LDX_ZPY ]]
				--
				cycles_taken += 4
				local base_address = fetch()
				local address = ADD_U8(base_address, Y)
				local value = read(address)
				X = value
				N, Z = value, value
			elseif op == 0xB7 then
				--[[ SMB_ZPB3 ]]
				--
				cycles_taken += 5
				local address = fetch()
				local bit_offset = 3
				local value = read(address)
				local result = bit32.replace(value, 1, bit_offset)
				write(address, result)
			elseif op == 0xB8 then
				--[[ CLV_IMP ]]
				--
				cycles_taken += 2
				V = false
			elseif op == 0xB9 then
				--[[ LDA_ABY ]]
				--
				cycles_taken += 4
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = ADD_U16(base_address, Y)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				local value = read(address)
				A = value
				N, Z = value, value
			elseif op == 0xBA then
				--[[ TSX_IMP ]]
				--
				cycles_taken += 2
				X = S
			elseif op == 0xBB then
				--[[ NOP_IMP ]]
				--
				cycles_taken += 1
			elseif op == 0xBC then
				--[[ LDY_ABX ]]
				--
				cycles_taken += 4
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = ADD_U16(base_address, X)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				local value = read(address)
				Y = value
				N, Z = value, value
			elseif op == 0xBD then
				--[[ LDA_ABX ]]
				--
				cycles_taken += 4
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = ADD_U16(base_address, X)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				local value = read(address)
				A = value
				N, Z = value, value
			elseif op == 0xBE then
				--[[ LDX_ABY ]]
				--
				cycles_taken += 4
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = ADD_U16(base_address, Y)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				local value = read(address)
				X = value
				N, Z = value, value
			elseif op == 0xBF then
				--[[ BBS_ZPR3 ]]
				--
				cycles_taken += 4
				local zp_addr = fetch()
				local offset = fetch()
				local bit_offset = 3
				local rel = if offset > 127 then offset - 256 else offset

				local base_address = zp_addr
				local value = read(zp_addr) -- This is required for the bit test
				local address = ADD_U16(PC, rel) -- PC is now at the start of the next instruction
				if bit32.extract(value, bit_offset) == 1 then
					cycles_taken += if SAME_PAGE(base_address, address) then 1 else 2
					PC = address
				end
			elseif op == 0xC0 then
				--[[ CPY_IMM ]]
				--
				cycles_taken += 2
				local value = fetch()
				local address = nil
				local base_address = nil
				local result = SUB_U8(Y, value)
				N, Z = result, result
				C = value <= Y
			elseif op == 0xC1 then
				--[[ CMP_IZX ]]
				--
				cycles_taken += 6
				local ptr = ADD_U8(fetch(), X)
				local base_address = CONCAT_U16(read(ptr), read(ADD_U8(ptr, 1)))
				local address = base_address

				local value = read(address)
				local result = SUB_U8(A, value)
				N, Z = result, result
				C = value <= A
			elseif op == 0xC2 then
				--[[ NOP_IMM ]]
				--
				cycles_taken += 2
				local value = fetch()
				local address = nil
				local base_address = nil
			elseif op == 0xC3 then
				--[[ NOP_IMP ]]
				--
				cycles_taken += 1
			elseif op == 0xC4 then
				--[[ CPY_ZP0 ]]
				--
				cycles_taken += 3
				local base_address = fetch()
				local address = base_address
				local value = read(address)
				local result = SUB_U8(Y, value)
				N, Z = result, result
				C = value <= Y
			elseif op == 0xC5 then
				--[[ CMP_ZP0 ]]
				--
				cycles_taken += 3
				local base_address = fetch()
				local address = base_address
				local value = read(address)
				local result = SUB_U8(A, value)
				N, Z = result, result
				C = value <= A
			elseif op == 0xC6 then
				--[[ DEC_ZP0 ]]
				--
				cycles_taken += 5
				local base_address = fetch()
				local address = base_address
				local value = read(address)
				local result = SUB_U8(value, 1)
				N, Z = result, result
				write(address, result)
			elseif op == 0xC7 then
				--[[ SMB_ZPB4 ]]
				--
				cycles_taken += 5
				local address = fetch()
				local bit_offset = 4
				local value = read(address)
				local result = bit32.replace(value, 1, bit_offset)
				write(address, result)
			elseif op == 0xC8 then
				--[[ INY_IMP ]]
				--
				cycles_taken += 2
				Y = ADD_U8(Y, 1)
				N, Z = Y, Y
			elseif op == 0xC9 then
				--[[ CMP_IMM ]]
				--
				cycles_taken += 2
				local value = fetch()
				local address = nil
				local base_address = nil
				local result = SUB_U8(A, value)
				N, Z = result, result
				C = value <= A
			elseif op == 0xCA then
				--[[ DEX_IMP ]]
				--
				cycles_taken += 2
				X = SUB_U8(X, 1)
				N, Z = X, X
			elseif op == 0xCB then
				--[[ WAI_IMP ]]
				--
				cycles_taken += 5
				self._waiting = true
				break
			elseif op == 0xCC then
				--[[ CPY_ABS ]]
				--
				cycles_taken += 4
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = base_address
				local value = read(address)
				local result = SUB_U8(Y, value)
				N, Z = result, result
				C = value <= Y
			elseif op == 0xCD then
				--[[ CMP_ABS ]]
				--
				cycles_taken += 4
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = base_address
				local value = read(address)
				local result = SUB_U8(A, value)
				N, Z = result, result
				C = value <= A
			elseif op == 0xCE then
				--[[ DEC_ABS ]]
				--
				cycles_taken += 6
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = base_address
				local value = read(address)
				local result = SUB_U8(value, 1)
				N, Z = result, result
				write(address, result)
			elseif op == 0xCF then
				--[[ BBS_ZPR4 ]]
				--
				cycles_taken += 4
				local zp_addr = fetch()
				local offset = fetch()
				local bit_offset = 4
				local rel = if offset > 127 then offset - 256 else offset

				local base_address = zp_addr
				local value = read(zp_addr) -- This is required for the bit test
				local address = ADD_U16(PC, rel) -- PC is now at the start of the next instruction
				if bit32.extract(value, bit_offset) == 1 then
					cycles_taken += if SAME_PAGE(base_address, address) then 1 else 2
					PC = address
				end
			elseif op == 0xD0 then
				--[[ BNE_REL ]]
				--
				cycles_taken += 2
				local offset = REINTERPRET_SIGNED(fetch())
				local base_address = PC
				local address = ADD_U16(base_address, offset)
				-- extra cycles should be handled by the operation
				if Z ~= 0 then
					cycles_taken += if SAME_PAGE(base_address, address) then 1 else 2
					PC = address
				end
			elseif op == 0xD1 then
				--[[ CMP_IZY ]]
				--
				cycles_taken += 5
				local ptr = fetch()
				local base_address = CONCAT_U16(read(ptr), read(ADD_U8(ptr, 1)))
				local address = ADD_U16(base_address, Y)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				local value = read(address)
				local result = SUB_U8(A, value)
				N, Z = result, result
				C = value <= A
			elseif op == 0xD2 then
				--[[ CMP_ZPI ]]
				--
				cycles_taken += 5
				local ptr = fetch()
				local base_address = CONCAT_U16(read(ptr), read(ADD_U8(ptr, 1)))
				local address = base_address
				local value = read(address)
				local result = SUB_U8(A, value)
				N, Z = result, result
				C = value <= A
			elseif op == 0xD3 then
				--[[ NOP_IMP ]]
				--
				cycles_taken += 1
			elseif op == 0xD4 then
				--[[ NOP_ZPX ]]
				--
				cycles_taken += 4
				local base_address = fetch()
				local address = ADD_U8(base_address, X)
			elseif op == 0xD5 then
				--[[ CMP_ZPX ]]
				--
				cycles_taken += 4
				local base_address = fetch()
				local address = ADD_U8(base_address, X)
				local value = read(address)
				local result = SUB_U8(A, value)
				N, Z = result, result
				C = value <= A
			elseif op == 0xD6 then
				--[[ DEC_ZPX ]]
				--
				cycles_taken += 6
				local base_address = fetch()
				local address = ADD_U8(base_address, X)
				local value = read(address)
				local result = SUB_U8(value, 1)
				N, Z = result, result
				write(address, result)
			elseif op == 0xD7 then
				--[[ SMB_ZPB5 ]]
				--
				cycles_taken += 5
				local address = fetch()
				local bit_offset = 5
				local value = read(address)
				local result = bit32.replace(value, 1, bit_offset)
				write(address, result)
			elseif op == 0xD8 then
				--[[ CLD_IMP ]]
				--
				cycles_taken += 2
				D = false
			elseif op == 0xD9 then
				--[[ CMP_ABY ]]
				--
				cycles_taken += 4
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = ADD_U16(base_address, Y)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				local value = read(address)
				local result = SUB_U8(A, value)
				N, Z = result, result
				C = value <= A
			elseif op == 0xDA then
				--[[ PHX_IMP ]]
				--
				cycles_taken += 3
				push(X)
			elseif op == 0xDB then
				--[[ STP_IMP ]]
				--
				cycles_taken += 2
				self._stopped = true
				break
			elseif op == 0xDC then
				--[[ NOP_ABX ]]
				--
				cycles_taken += 4
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = ADD_U16(base_address, X)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
			elseif op == 0xDD then
				--[[ CMP_ABX ]]
				--
				cycles_taken += 4
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = ADD_U16(base_address, X)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				local value = read(address)
				local result = SUB_U8(A, value)
				N, Z = result, result
				C = value <= A
			elseif op == 0xDE then
				--[[ DEC_ABX ]]
				--
				cycles_taken += 7
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = ADD_U16(base_address, X)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				local value = read(address)
				local result = SUB_U8(value, 1)
				N, Z = result, result
				write(address, result)
			elseif op == 0xDF then
				--[[ BBS_ZPR5 ]]
				--
				cycles_taken += 4
				local zp_addr = fetch()
				local offset = fetch()
				local bit_offset = 5
				local rel = if offset > 127 then offset - 256 else offset

				local base_address = zp_addr
				local value = read(zp_addr) -- This is required for the bit test
				local address = ADD_U16(PC, rel) -- PC is now at the start of the next instruction
				if bit32.extract(value, bit_offset) == 1 then
					cycles_taken += if SAME_PAGE(base_address, address) then 1 else 2
					PC = address
				end
			elseif op == 0xE0 then
				--[[ CPX_IMM ]]
				--
				cycles_taken += 2
				local value = fetch()
				local address = nil
				local base_address = nil
				local result = SUB_U8(X, value)
				N, Z = result, result
				C = value <= X
			elseif op == 0xE1 then
				--[[ SBC_IZX ]]
				--
				cycles_taken += 6
				local ptr = ADD_U8(fetch(), X)
				local base_address = CONCAT_U16(read(ptr), read(ADD_U8(ptr, 1)))
				local address = base_address

				local value = read(address)
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

					if lo < 0 then
						lo -= 0x06
						hi -= 0x10
					end
					if hi < 0 then
						hi -= 0x60
					end

					local binary_diff = A - value - (if C then 0 else 1)
					V = bit32.band(bit32.bxor(A, value), bit32.bxor(A, binary_diff), 0x80) ~= 0

					C = binary_diff >= 0
					A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
					N, Z = A, A -- 65C02: N and Z are valid!
				end
			elseif op == 0xE2 then
				--[[ NOP_IMM ]]
				--
				cycles_taken += 2
				local value = fetch()
				local address = nil
				local base_address = nil
			elseif op == 0xE3 then
				--[[ NOP_IMP ]]
				--
				cycles_taken += 1
			elseif op == 0xE4 then
				--[[ CPX_ZP0 ]]
				--
				cycles_taken += 3
				local base_address = fetch()
				local address = base_address
				local value = read(address)
				local result = SUB_U8(X, value)
				N, Z = result, result
				C = value <= X
			elseif op == 0xE5 then
				--[[ SBC_ZP0 ]]
				--
				cycles_taken += 3
				local base_address = fetch()
				local address = base_address
				local value = read(address)
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

					if lo < 0 then
						lo -= 0x06
						hi -= 0x10
					end
					if hi < 0 then
						hi -= 0x60
					end

					local binary_diff = A - value - (if C then 0 else 1)
					V = bit32.band(bit32.bxor(A, value), bit32.bxor(A, binary_diff), 0x80) ~= 0

					C = binary_diff >= 0
					A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
					N, Z = A, A -- 65C02: N and Z are valid!
				end
			elseif op == 0xE6 then
				--[[ INC_ZP0 ]]
				--
				cycles_taken += 5
				local base_address = fetch()
				local address = base_address
				local value = read(address)
				local result = ADD_U8(value, 1)
				N, Z = result, result
				write(address, result)
			elseif op == 0xE7 then
				--[[ SMB_ZPB6 ]]
				--
				cycles_taken += 5
				local address = fetch()
				local bit_offset = 6
				local value = read(address)
				local result = bit32.replace(value, 1, bit_offset)
				write(address, result)
			elseif op == 0xE8 then
				--[[ INX_IMP ]]
				--
				cycles_taken += 2
				X = ADD_U8(X, 1)
				N, Z = X, X
			elseif op == 0xE9 then
				--[[ SBC_IMM ]]
				--
				cycles_taken += 2
				local value = fetch()
				local address = nil
				local base_address = nil
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

					if lo < 0 then
						lo -= 0x06
						hi -= 0x10
					end
					if hi < 0 then
						hi -= 0x60
					end

					local binary_diff = A - value - (if C then 0 else 1)
					V = bit32.band(bit32.bxor(A, value), bit32.bxor(A, binary_diff), 0x80) ~= 0

					C = binary_diff >= 0
					A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
					N, Z = A, A -- 65C02: N and Z are valid!
				end
			elseif op == 0xEA then
				--[[ NOP_IMP ]]
				--
				cycles_taken += 2
			elseif op == 0xEB then
				--[[ NOP_IMP ]]
				--
				cycles_taken += 1
			elseif op == 0xEC then
				--[[ CPX_ABS ]]
				--
				cycles_taken += 4
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = base_address
				local value = read(address)
				local result = SUB_U8(X, value)
				N, Z = result, result
				C = value <= X
			elseif op == 0xED then
				--[[ SBC_ABS ]]
				--
				cycles_taken += 4
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = base_address
				local value = read(address)
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

					if lo < 0 then
						lo -= 0x06
						hi -= 0x10
					end
					if hi < 0 then
						hi -= 0x60
					end

					local binary_diff = A - value - (if C then 0 else 1)
					V = bit32.band(bit32.bxor(A, value), bit32.bxor(A, binary_diff), 0x80) ~= 0

					C = binary_diff >= 0
					A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
					N, Z = A, A -- 65C02: N and Z are valid!
				end
			elseif op == 0xEE then
				--[[ INC_ABS ]]
				--
				cycles_taken += 6
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = base_address
				local value = read(address)
				local result = ADD_U8(value, 1)
				N, Z = result, result
				write(address, result)
			elseif op == 0xEF then
				--[[ BBS_ZPR6 ]]
				--
				cycles_taken += 4
				local zp_addr = fetch()
				local offset = fetch()
				local bit_offset = 6
				local rel = if offset > 127 then offset - 256 else offset

				local base_address = zp_addr
				local value = read(zp_addr) -- This is required for the bit test
				local address = ADD_U16(PC, rel) -- PC is now at the start of the next instruction
				if bit32.extract(value, bit_offset) == 1 then
					cycles_taken += if SAME_PAGE(base_address, address) then 1 else 2
					PC = address
				end
			elseif op == 0xF0 then
				--[[ BEQ_REL ]]
				--
				cycles_taken += 2
				local offset = REINTERPRET_SIGNED(fetch())
				local base_address = PC
				local address = ADD_U16(base_address, offset)
				-- extra cycles should be handled by the operation
				if Z == 0 then
					cycles_taken += if SAME_PAGE(base_address, address) then 1 else 2
					PC = address
				end
			elseif op == 0xF1 then
				--[[ SBC_IZY ]]
				--
				cycles_taken += 5
				local ptr = fetch()
				local base_address = CONCAT_U16(read(ptr), read(ADD_U8(ptr, 1)))
				local address = ADD_U16(base_address, Y)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				local value = read(address)
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

					if lo < 0 then
						lo -= 0x06
						hi -= 0x10
					end
					if hi < 0 then
						hi -= 0x60
					end

					local binary_diff = A - value - (if C then 0 else 1)
					V = bit32.band(bit32.bxor(A, value), bit32.bxor(A, binary_diff), 0x80) ~= 0

					C = binary_diff >= 0
					A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
					N, Z = A, A -- 65C02: N and Z are valid!
				end
			elseif op == 0xF2 then
				--[[ SBC_ZPI ]]
				--
				cycles_taken += 5
				local ptr = fetch()
				local base_address = CONCAT_U16(read(ptr), read(ADD_U8(ptr, 1)))
				local address = base_address
				local value = read(address)
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

					if lo < 0 then
						lo -= 0x06
						hi -= 0x10
					end
					if hi < 0 then
						hi -= 0x60
					end

					local binary_diff = A - value - (if C then 0 else 1)
					V = bit32.band(bit32.bxor(A, value), bit32.bxor(A, binary_diff), 0x80) ~= 0

					C = binary_diff >= 0
					A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
					N, Z = A, A -- 65C02: N and Z are valid!
				end
			elseif op == 0xF3 then
				--[[ NOP_IMP ]]
				--
				cycles_taken += 1
			elseif op == 0xF4 then
				--[[ NOP_ZPX ]]
				--
				cycles_taken += 4
				local base_address = fetch()
				local address = ADD_U8(base_address, X)
			elseif op == 0xF5 then
				--[[ SBC_ZPX ]]
				--
				cycles_taken += 4
				local base_address = fetch()
				local address = ADD_U8(base_address, X)
				local value = read(address)
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

					if lo < 0 then
						lo -= 0x06
						hi -= 0x10
					end
					if hi < 0 then
						hi -= 0x60
					end

					local binary_diff = A - value - (if C then 0 else 1)
					V = bit32.band(bit32.bxor(A, value), bit32.bxor(A, binary_diff), 0x80) ~= 0

					C = binary_diff >= 0
					A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
					N, Z = A, A -- 65C02: N and Z are valid!
				end
			elseif op == 0xF6 then
				--[[ INC_ZPX ]]
				--
				cycles_taken += 6
				local base_address = fetch()
				local address = ADD_U8(base_address, X)
				local value = read(address)
				local result = ADD_U8(value, 1)
				N, Z = result, result
				write(address, result)
			elseif op == 0xF7 then
				--[[ SMB_ZPB7 ]]
				--
				cycles_taken += 5
				local address = fetch()
				local bit_offset = 7
				local value = read(address)
				local result = bit32.replace(value, 1, bit_offset)
				write(address, result)
			elseif op == 0xF8 then
				--[[ SED_IMP ]]
				--
				cycles_taken += 2
				D = true
			elseif op == 0xF9 then
				--[[ SBC_ABY ]]
				--
				cycles_taken += 4
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = ADD_U16(base_address, Y)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				local value = read(address)
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

					if lo < 0 then
						lo -= 0x06
						hi -= 0x10
					end
					if hi < 0 then
						hi -= 0x60
					end

					local binary_diff = A - value - (if C then 0 else 1)
					V = bit32.band(bit32.bxor(A, value), bit32.bxor(A, binary_diff), 0x80) ~= 0

					C = binary_diff >= 0
					A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
					N, Z = A, A -- 65C02: N and Z are valid!
				end
			elseif op == 0xFA then
				--[[ PLX_IMP ]]
				--
				cycles_taken += 4
				X = pull()
				N, Z = X, X
			elseif op == 0xFB then
				--[[ NOP_IMP ]]
				--
				cycles_taken += 1
			elseif op == 0xFC then
				--[[ NOP_ABX ]]
				--
				cycles_taken += 4
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = ADD_U16(base_address, X)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
			elseif op == 0xFD then
				--[[ SBC_ABX ]]
				--
				cycles_taken += 4
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = ADD_U16(base_address, X)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				local value = read(address)
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

					if lo < 0 then
						lo -= 0x06
						hi -= 0x10
					end
					if hi < 0 then
						hi -= 0x60
					end

					local binary_diff = A - value - (if C then 0 else 1)
					V = bit32.band(bit32.bxor(A, value), bit32.bxor(A, binary_diff), 0x80) ~= 0

					C = binary_diff >= 0
					A = bit32.band(hi + bit32.band(lo, 0x0F), 0xFF)
					N, Z = A, A -- 65C02: N and Z are valid!
				end
			elseif op == 0xFE then
				--[[ INC_ABX ]]
				--
				cycles_taken += 7
				local base_address = CONCAT_U16(fetch(), fetch())
				local address = ADD_U16(base_address, X)
				if not SAME_PAGE(base_address, address) then
					cycles_taken += 1
				end
				local value = read(address)
				local result = ADD_U8(value, 1)
				N, Z = result, result
				write(address, result)
			elseif op == 0xFF then
				--[[ BBS_ZPR7 ]]
				--
				cycles_taken += 4
				local zp_addr = fetch()
				local offset = fetch()
				local bit_offset = 7
				local rel = if offset > 127 then offset - 256 else offset

				local base_address = zp_addr
				local value = read(zp_addr) -- This is required for the bit test
				local address = ADD_U16(PC, rel) -- PC is now at the start of the next instruction
				if bit32.extract(value, bit_offset) == 1 then
					cycles_taken += if SAME_PAGE(base_address, address) then 1 else 2
					PC = address
				end
			else
				error("worm")
			end
		end
	end

	self._a, self._x, self._y, self._s, self._pc = A, X, Y, S, PC
	self._n, self._z, self._v, self._d, self._i, self._c = N, Z :: number, V, D, I, C
	self._cycles += cycles_taken
	return cycles_taken
end

function Wdc65C02.reset(self: Wdc65C02) end
function Wdc65C02.irq(self: Wdc65C02, enabled: boolean) end
function Wdc65C02.nmi(self: Wdc65C02) end

return Wdc65C02
