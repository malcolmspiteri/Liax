typedef uint16_t Elf32_Half;
typedef uint32_t Elf32_Word, Elf32_Sword, Elf32_Off, Elf32_Addr;

/* Identification array dimensions */
#define EI_MAG0 0 // File identification
#define EI_MAG1 1 // File identification
#define EI_MAG2 2 // File identification
#define EI_MAG3 3 // File identification
#define EI_CLASS 4 // File class
#define EI_DATA 5 // Data encoding
#define EI_VERSION 6 // File version
#define EI_PAD 7 // Start of padding bytes
#define EI_NIDENT 16 // Size of e_ident[]

/* Magic number */
#define ELFMAG0 0x7f // e_ident[EI_MAG0]
#define ELFMAG1 'E' // e_ident[EI_MAG1]
#define ELFMAG2 'L' // e_ident[EI_MAG2]
#define ELFMAG3 'F' // e_ident[EI_MAG3]

/* Processor class EI_CLASS[EI_CLASS] */
#define ELFCLASSNONE 0 // Invalid class
#define ELFCLASS32 1 // 32-bit objects
#define ELFCLASS64 2 // 64-bit objects

/* Encoding e_ident[EI_DATA] */
#define ELFDATANONE 0 // Invalid data encoding
#define ELFDATA2LSB 1 // Least significant byte
#define ELFDATA2MSB 2 // Most significant byte

/* Section type */
#define SHT_NULL 0
#define SHT_PROGBITS 1
#define SHT_SYMTAB 2
#define SHT_STRTAB 3
#define SHT_RELA 4
#define SHT_HASH 5
#define SHT_DYNAMIC 6
#define SHT_NOTE 7
#define SHT_NOBITS 8
#define SHT_REL 9
#define SHT_SHLIB 10
#define SHT_DYNSYM 11
#define SHT_LOPROC 0x70000000
#define SHT_HIPROC 0x7fffffff
#define SHT_LOUSER 0x80000000
#define SHT_HIUSER 0xffffffff

typedef struct {
	unsigned char e_ident[EI_NIDENT];
	Elf32_Half e_type;
	Elf32_Half e_machine;
	Elf32_Word e_version;
	Elf32_Addr e_entry;
	Elf32_Off e_phoff;
	Elf32_Off e_shoff;
	Elf32_Word e_flags;
	Elf32_Half e_ehsize;
	Elf32_Half e_phentsize;
	Elf32_Half e_phnum;
	Elf32_Half e_shentsize;
	Elf32_Half e_shnum;
	Elf32_Half e_shstrndx;
} Elf32_Ehdr;

typedef struct {
  Elf32_Word sh_name;
  Elf32_Word sh_type;
  Elf32_Word sh_flags;
  Elf32_Addr sh_addr;
  Elf32_Off sh_offset;
  Elf32_Word sh_size;
  Elf32_Word sh_link;
  Elf32_Word sh_info;
  Elf32_Word sh_addralign;
  Elf32_Word sh_entsize;
} Elf32_Shdr;
