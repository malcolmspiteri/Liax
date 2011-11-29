#include <stdio.h>
#include "mzdos.h"

int is_mzdos_exe(MZDOS_EXE *stub);
void print_mzdos_exe_header(MZDOS_EXE *stub);

int main(void) {
	
	char *filename = "C:\\Projects\\PEInspector\\Tail.exe";
	
	FILE *f = fopen(filename, "r");
	
	setvbuf(f, NULL, _IONBF, 0);

	//size_t fread(void *ptr, size_t size, size_t nelem, FILE *stream);
	MZDOS_EXE dos_stub;
	
	fread(&dos_stub, sizeof(dos_stub), 1, f);
	
	if (IS_MZDOS_EXE == is_mzdos_exe(&dos_stub)) {
		print_mzdos_exe_header(&dos_stub);
		printf("\nPE starts at %p", dos_stub.lfanew);		
	};
	
	fclose(f);
	
	
}

int is_mzdos_exe(MZDOS_EXE *stub) {

	if (stub->signature == MZDOS_EXE_MAGIC) {
		return IS_MZDOS_EXE;
	} else {
		return IS_NOT_MZDOS_EXE;
	}

}

void print_mzdos_exe_header(MZDOS_EXE *stub) {

	printf("MS-DOS Header\n=============");
	printf("\nBytes in last block:\t%d", stub->bytes_in_last_block);
	printf("\nBlocks in file:\t\t%d", stub->blocks_in_file);
	printf("\nNumber of relocations:\t%d", stub->num_relocs);

}
