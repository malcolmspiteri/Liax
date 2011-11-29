%ifndef _PE32_INC
%define _PE32_INC

%define IMAGE_FILE_MACHINE_UNKNOWN			0x0		;; Contents assumed to be applicable to any machine type.
%define IMAGE_FILE_MACHINE_ALPHA			0x184	;; Alpha AXP™.
%define IMAGE_FILE_MACHINE_ARM				0x1c0	
%define IMAGE_FILE_MACHINE_ALPHA64			0x284	;; Alpha AXP™ 64-bit.
%define IMAGE_FILE_MACHINE_I386				0x14c	;; Intel 386 or later, and compatible processors.
%define IMAGE_FILE_MACHINE_IA64				0x200	;; Intel IA64™
%define IMAGE_FILE_MACHINE_M68K				0x268	;; Motorola 68000 series.
%define IMAGE_FILE_MACHINE_MIPS16			0x266	
%define IMAGE_FILE_MACHINE_MIPSFPU			0x366	;; MIPS with FPU
%define IMAGE_FILE_MACHINE_MIPSFPU16		0x466	;; MIPS16 with FPU
%define IMAGE_FILE_MACHINE_POWERPC			0x1f0	;; Power PC, little endian.
%define IMAGE_FILE_MACHINE_R3000			0x162	
%define IMAGE_FILE_MACHINE_R4000			0x166	;; MIPS® little endian.
%define IMAGE_FILE_MACHINE_R10000			0x168	
%define IMAGE_FILE_MACHINE_SH3				0x1a2	;; Hitachi SH3
%define IMAGE_FILE_MACHINE_SH4				0x1a6	;; Hitachi SH4
%define IMAGE_FILE_MACHINE_THUMB			0x1c2	

%define IMAGE_FILE_RELOCS_STRIPPED			0x0001
%define IMAGE_FILE_EXECUTABLE_IMAGE			0x0002
%define IMAGE_FILE_LINE_NUMS_STRIPPED		0x0004
%define IMAGE_FILE_LOCAL_SYMS_STRIPPED		0x0008
%define IMAGE_FILE_AGGRESSIVE_WS_TRIM		0x0010
%define IMAGE_FILE_LARGE_ADDRESS_AWARE		0x0020
%define IMAGE_FILE_16BIT_MACHINE			0x0040
%define IMAGE_FILE_BYTES_REVERSED_LO		0x0080
%define IMAGE_FILE_32BIT_MACHINE			0x0100
%define IMAGE_FILE_DEBUG_STRIPPED			0x0200
%define IMAGE_FILE_REMOVABLE_RUN_FROM_SWAP	0x0400
%define IMAGE_FILE_SYSTEM					0x1000
%define IMAGE_FILE_DLL						0x2000
%define IMAGE_FILE_UP_SYSTEM_ONLY			0x4000
%define IMAGE_FILE_BYTES_REVERSED_HI		0x8000

;; COFF header plus signature
struc coff_file_header

	Signature 				resd 	1
    Machine:				resw	1
	NumberOfSections:		resw	1
	TimeDateStamp:			resd	1
	PointerToSymbolTable: 	resd 	1
	NumberOfSymbols: 		resd 	1
	SizeOfOptionalHeader: 	resw 	1
	Characteristics: 		resw 	1
	
endstruc

struc optional_header
	;; Standard fields
	Magic							resw 1
	MajorLinkerVersion				resb 1
	MinorLinkerVersion				resb 1
	SizeOfCode						resd 1
	SizeOfInitializedData			resd 1
	SizeOfUninitializedData			resd 1
	AddressOfEntryPoint
	BaseOfCode
	BaseOfData
	;; NT specific fields
	ImageBase
	SectionAlignment
	FileAlignment
	MajorOperatingSystemVersion		
	MinorOperatingSystemVersion
	MajorImageVersion
	MinorImageVersion
	MajorSubsystemVersion
	MinorSubsystemVersion
	Reserved
	SizeOfImage
	SizeOfHeaders
	CheckSum
	Subsystem
	DLL Characteristics
	SizeOfStackReserve
	SizeOfStackCommit
	SizeOfHeapReserve
	SizeOfHeapCommit
	LoaderFlags
	NumberOfRvaAndSizes

endstruc 

%endif
