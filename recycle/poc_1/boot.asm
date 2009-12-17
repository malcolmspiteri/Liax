; Source name     : boot.asm
; Executable name : boott.bin
; Code model:     : Real mode flat model
; Version         : 1.0
; Created date    : 27/11/2009
; Last update     : 27/11/2009
; Author          : Malcolm Spiteri
; Description     : MelitaOS Bootstrapper

%define INIT_OFFSET 0x7c00
%define RELOC_OFFSET 0x0050 ; Just above the BIOS data area (BDA)
%define KERNEL_OFFSET 0x0250 ; This is where the kernel will be loaded...just above the boot strapper
  
bits 16			; Set 16 bit code generation
org INIT_OFFSET ; We are loaded by BIOS at 0x7C00:0x0000

start:	
	;Relocate the boot strapper to RELOC_OFFSET:0x0000
	mov	ax,INIT_OFFSET
	mov	di,ax
	mov	ax,RELOC_OFFSET
	mov	si,ax
	mov	cx,256
	cld 					; Clear the direction flag so that index registers are incremented
	repne 
	movsw	
	jmp 0x0063

.continue_start:

	mov si,loading_msg		; Print message
    call show_msg	

hang: jmp hang
	
; Print a 0-terminated string on the screen
show_msg:

    lodsb           ; AL = [DS:SI]
    or al,al        ; Set zero flag if al=0
    jz .done        ; Jump to .done if zero flag is set
    mov ah, 0x0E	; Video function 0Eh
    mov bx, 0x0007	; Color
    int 0x10
    jmp show_msg	; Load characters until AL=0
.done:
    retn
		
	loading_msg   db 'MelitaOS is loading...', 0 ;Here's our message

	times 510 - ($-$$) db 0		; We have to be 512 bytes. Clear the rest of the bytes with 0
	dw 0xAA55					; Boot Signiture
