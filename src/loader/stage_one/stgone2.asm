;;; Name		: stgone
;;; Version		: 0.1
;;; Date		: 27/11/2009
;;; Author		: Malcolm Spiteri
;;; Description		: Stage-1 bootloader

bits 16	
org 0x0	; Assuming we are at 0x07c0:0x0000

%define BOOT_SECTOR_SIZE 	0x0200	; 512-bytes
%define INIT_SEG 		0x07C0	; Actually we start at 0x0000:0x07C0
%define RELOC_SEG 		0x0050	; Stage one will relocate itself to this segment

;;; The stack will operate in the first 64KiB of memory, just beneath where the kernel will be loaded 
%define STACK_SEG 		0x0000
%define STACK_OFFSET 		0xFFFE

;;; Stage-1.5 bootloader will be loaded just after Stage-1
%define STGOPF_SEG		0x0000
%define STGOPF_OFFSET		0x0700
%define STGOPF_SIZE_SECTORS	7

%define BOOT_DEVICE 		0x0	; Floppy
%define VOLUME_LABEL 		'MELITE', 0x20, 0x20, 0x20, 0x20, 0x20

%include "./src/loader/include/fat12.inc"

start:	
	jmp post_oem

oemb:

istruc fat_oem_block

      at oem,			db	'Melite  '
      at bytes_per_sector,	dw 	512
      at sectors_per_cluster,	db	1
      at reserved_sectors,	dw	8
      at no_fats,		db	2
      at no_root_entries,	dw	224
      at no_sectors,		dw	2880
      at media,			db	0xf0
      at sectors_per_fat,	dw	9
      at sectors_per_track,	dw	18
      at heads_per_cylinder,	dw	2
      at no_hidden_sectors,	dd	0
      at no_large_sectors,	dd	0
      at drive_number,		db	0
      at unused,		db	0
      at ext_boot_sig,		db 	0x29
      at serial_number,		dd	0x3ced2208
      at valume_label,		db 	VOLUME_LABEL
      at file_system,		db 	FAT12_FILE_SYSTEM

iend

post_oem:

	jmp INIT_SEG:relocate

relocate:	
	;; Relocate the bootstrap to RELOC_SEG
	mov ax,INIT_SEG
	mov ds,ax
	mov ax,RELOC_SEG
	mov es,ax
	xor di,di
	xor si,si	
	mov cx,0x0100 ; 256 iterations (256 x 2bytes per iteration moved = 512 bytes moved)
	cld ; Clear the direction flag so that index registers are incremented
	repne
	movsw	
	mov ds,ax ; Set the data segment register to the new segment address, cs should point to the new location after the following jump
	jmp RELOC_SEG:real_start

%include "./src/loader/include/bios.inc"
%include "./src/loader/include/util.inc"
%include "./src/loader/include/stdio.inc"

real_start:

.setup_stack:
	cli ; clear interupts
	mov ax,STACK_SEG
	mov ss,ax
	mov sp,STACK_OFFSET
	sti ; start interupts

	;; Loas Stage-1.5
	CALL_PROC load_stgopf

	;; Jump to Stage-1.5
	mov ax,STGOPF_SEG
	push ax
	mov ax,STGOPF_OFFSET
	push ax
	retf

;;; Should never arrive here
hang: 	jmp hang

load_stgopf:
	BIOS_READ_SECTORS STGOPF_SEG, STGOPF_OFFSET, 7d, stgopf_dchs, err_handler
.end:
	ret

err_handler:
	BIOS_SET_VIDEO_MODE MODE_640x350_16_COLOR_GRAPHICS
	CALL_PROC print, ERROR_MSG, BIOS_COLOR(COLOR_BLACK, COLOR_RED)
	jmp hang

messages:

ERROR_MSG db 'ERROR', 0

stgopf_dchs:

istruc dchs
	at drive,		db 0x0
	at cylinder,		db 0x0
	at head,		db 0x0
	at sector,		db 0x2
iend

times 510 - ($-$$) db 0	; We have to be 512 bytes. Clear the rest of the bytes with 0
dw 0xAA55 ; Boot Signiture