#define WHITE_TXT 0x07 // white on black text

unsigned int k_printf(char *message, unsigned int line);

void k_main()
{	
	k_printf("Hi!\nWelcome to MalcOS", 10);
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
