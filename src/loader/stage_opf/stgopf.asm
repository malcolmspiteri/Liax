;; Name:		stgopf
;; Version:		0.1
;; Date:		13/12/2010
;; Author:		Malcolm Spiteri
;; Description:		Stage-1.5 bootloader
	
bits 16
org 0x700

section .text

	jmp start
	
%include "./src/loader/include/util.inc"
%include "./src/loader/include/bios.inc"
%include "./src/loader/include/stdio.inc"
%include "./src/loader/include/fat12.inc"

start:
	mov ax,cs
	mov ds,ax
	mov es,ax
	CALL_PROC clear_screen
	BIOS_SET_CURSOR_POSITION
	PRINT_LINE 'System is loading...'
	PRINT_STRING 'Stage-2...'
	CALL_PROC load_file, loader_fname, 0x0000, 0x0E00, 0x0000, 0x2000
	PRINT_LINE 'OK'
	PRINT_STRING 'Kernel...'
 	CALL_PROC load_file, loader_fname, 0x0000, 0x0E00, 0x0000, 0x4000
	PRINT_LINE 'OK'
	jmp hang
	push WORD 0x0000
	push WORD 0x2000
	retf

hang: 	jmp hang

section .data

loader_fname:	db 'MELOADERSYS'
kernel_fname:	db 'KERNEL  EXE'
	
times 3584 - ($-$$) db 0