%ifndef _STDIO_INC
%define _STDIO_INC

%ifndef _UTIL_INC
%include "./src/loader/include/util.inc"
%endif

%ifndef _BIOS_INC
%include "./src/loader/include/bios.inc"
%endif

%define BDA_SEGMENT 0x0040
%define CR 0x0D
%define LF 0x0A

print:	
.init:
	mov si, GET_ARG(1)	; Pointer to the start of the text
	mov cx, GET_ARG(2)	; Color
.start:
	lodsb			; AL = [DS:SI]
	or al,al		; Set zero flag if AL=0
	jz .end			
	BIOS_WRITE_CHAR_TTY cl
	jmp .start		; Load chars until AL=0
.end:
	ret

%macro PRINT_STRING 1+
	%ifstr %1
		[section .data] 
		%%str:	
			db %1
			db 0x0
		%%endstr: 
			
			__SECT__ 
			
			CALL_PROC print, %%str, DEFAULT_COLOR_SCHEME
	%else
		CALL_PROC print, %1, DEFAULT_COLOR_SCHEME
	%endif
%endmacro

%macro PRINT_LINE 1+
	[section .data] 
	%%crlf db 0x0D, 0x0A, 0
	__SECT__ 
	PRINT_STRING %1
	PRINT_STRING %%crlf
%endmacro

%ifndef STGONE

clear_screen:
	; Clear the screen using BIOS video service
	mov ax,BDA_SEGMENT
	mov fs,ax  			; for getting screen parameters. 
	mov di,0x0084 		; rows on screen -1, 
	mov si,0x004A 		; columns on screen, 
	mov bl,BYTE [fs:si]
	dec bl
	BIOS_SCROLL_UP_WINDOW 0x0, 0x07, 0x0, 0x0, BYTE [fs:di], bl
	ret

;; Converts a word to its ascii representation and writes to a given memory location along with a terminating character 0x0
;; Parameter 1 - the word to be converted
word_to_ascii:
	[section .bss]
wta_ret:
	resw 2
	resb 1
	__SECT__
	mov BYTE[wta_ret+4], BYTE 0x0
	mov cx, GET_ARG(1)	; set cx to the value of the word to convert
	; From right to left
	; 1st character
	CALL_PROC nibble_to_acscii, cx
	mov BYTE[wta_ret+3], al
	; 2nd character
	ror cx, 0x4
	CALL_PROC nibble_to_acscii, cx
	mov BYTE[wta_ret+2], al
	; 3rd character
	ror cx, 0x4
	CALL_PROC nibble_to_acscii, cx
	mov BYTE[wta_ret+1], al
	; 4th character
	ror cx, 0x4
	CALL_PROC nibble_to_acscii, cx
	mov BYTE[wta_ret], al
	xor ax,ax
	mov ax,wta_ret
.success:
	ret

; Converts value of a nibble to its ascii representation and stores in al
nibble_to_acscii:

	mov ax,GET_ARG(1)
	and ax,0x000F ; Clear out HOB and LOB's HON
	cmp al,0xA
	jae .alphabet_char
.numeric_char:
	; In this case we just add 0x30
	add al,0x30
	jmp .end
.alphabet_char:
	add al,0x37 ; 'A' char code is 0x41 but since our value is at minimum 0xA we need to take that into account
.end:
	ret

%endif

%endif