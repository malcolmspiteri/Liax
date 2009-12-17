; Source name     : boot.asm
; Executable name : boott.bin
; Code model:     : Real mode flat model
; Version         : 1.0
; Created date    : 27/11/2009
; Last update     : 27/11/2009
; Author          : Malcolm Spiteri
; Description     : MelitaOS Bootstrapper

%define INIT_SEG 0x07C0
%define RELOC_SEG 0x0050 					; Just above the BIOS data area (BDA)
  
bits 16										; Set 16 bit code generation
org 0x0										; We are loaded by BIOS at 0x0000:0x7C00

	jmp INIT_SEG:init
init:	
	;Relocate the boot strapper to 0x0000:RELOC_SEG
	mov	ax,INIT_SEG
	mov	ds,ax
	mov	ax,RELOC_SEG
	mov	es,ax
	xor di,di
	xor si,si	
	mov	cx,256
	cld										; Clear the direction flag so that index registers are incremented
	repne 
	movsw	
	jmp RELOC_SEG:start

start:

	mov ax,RELOC_SEG
	mov ds,ax								; Set the data segment register to the new segment address
	mov si,loading_msg						; Print message
    call println
	mov si,loading_msg2						; Print message
    call println

hang: jmp hang
	
%include "bios_utils.asm"

loading_msg   db 'MalcolmOS is loading...', 0
loading_msg2   db '=======================', 0

times 510 - ($-$$) db 0					; We have to be 512 bytes. Clear the rest of the bytes with 0
dw 0xAA55								; Boot Signiture