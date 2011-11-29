#include <stdio.h>
#include <stdlib.h>
#include "elf.h"

void tidyUp(FILE *file, char *message);

int main(int argc, char *argv[]) {
	
	if (argc != 2) {
        printf("Usage: %s filename\n", argv[0]);
        exit(EXIT_FAILURE);
    }

	FILE *elff;
	if ((elff = fopen(argv[1], "rb")) == NULL) {
        printf("Can't open %s\n", argv[1]);
        exit(EXIT_FAILURE);
    }
	
	Elf32_Ehdr header;	
	size_t read;
	if ((read = fread(&header, sizeof(char), sizeof(Elf32_Ehdr), elff)) != sizeof(Elf32_Ehdr)) {
        printf("Error reading %s\n", argv[1]);
        exit(EXIT_FAILURE);
    }
		
	if (header.e_ident[EI_MAG0] == 0x7f &&
		header.e_ident[EI_MAG1] == 'E' &&
		header.e_ident[EI_MAG2] == 'L' &&
		header.e_ident[EI_MAG3] == 'F') {
		printf("File %s is an ELF file\n",argv[1]);
	} else {
		printf("File %s is not an ELF file\n",argv[1]);
	}
	
	unsigned char kuku[4];
	void *kkk;
	kkk = memcpy(kuku, (header.e_ident+1), 3);
	kuku[3] = '\0';
	printf("kuku: %s\n",kkk);
	printf("header: %p\n",(header.e_ident+1));
	printf("Identification header is %x%c%c%c\n", header.e_ident[0], header.e_ident[1], header.e_ident[2], header.e_ident[3]);
	printf("Read %d bytes\n", read);
	
	// Let's see of there is a section header table
	if (header.e_shoff != 0) {
		printf("Section header table is located at %d.\nThere are %d sections and with size %d\n", header.e_shoff, header.e_shnum, header.e_shentsize);
		char i;
		Elf32_Shdr section[header.e_shnum];
		Elf32_Shdr *strtab;
		fpos_t pos = header.e_shoff;		
		fsetpos(elff, &pos);
		for (i = 0; i < header.e_shnum; i++) {
			printf("Position in file: %d\n",ftell(elff));			
			fread(&section[i], sizeof(char), sizeof(Elf32_Shdr), elff);			
			printf("Section %d\n",i+1);
			printf("Name %d\n", section[i].sh_name);
			printf("Type %d\n", section[i].sh_type);
			printf("size %d\n", section[i].sh_size);
			if ( section[i].sh_type == SHT_STRTAB) {
				strtab = &section[i];
				printf("We found a string table. Yipee!");
			}
		}
	} else {
		printf("The ELF file does not have a section header table.\n");
	}
	
	// Done. Close the file and exit
	if (fclose(elff) != 0)
        fprintf(stderr,"Error closing file\n");
	
	return EXIT_SUCCESS;
}

void tidyUp(FILE *file, char *message) {
	if (fclose(file) != 0)
        fprintf(stderr,"Error closing file\n");	
	
}

