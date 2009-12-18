#define WHITE_TXT 0x07 // white on black text

unsigned int k_printf(char *message, unsigned int line);

ld_main() // like main in a normal C program
{
	k_printf("Hi!\nHow's this for a starter OS?", 0);
};

unsigned int k_printf(char *message, unsigned int line) // the message and then the line #
{
	char *vidmem = (char *) 0xb8000;
	unsigned int i=0;

	i=(line*80*2);

	while(*message!=0)
	{
		if(*message=='\n')
		{
			line++;
			i=(line*80*2);
			*message++;
		} else {
			vidmem[i]=*message;
			*message++;
			i++;
			vidmem[i]=WHITE_TXT;
			i++;
		};
	};

	return(1);
};
