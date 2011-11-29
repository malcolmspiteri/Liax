%ifndef _FAT12_INC
%define _FAT12_INC

%ifndef STGONE

%ifndef _STRING_INC
%include "./src/loader/include/string.inc"
%endif

%ifndef _BIOS_INC
%include "./src/loader/include/bios.inc"
%endif

%ifndef _STDIO_INC
%include "./src/loader/include/stdio.inc"
%endif

%ifndef _DEBUG_INC
%include "./src/loader/include/debug.inc"
%endif

%endif

%define FAT12_FILE_SYSTEM 'FAT12', 0x20, 0x20, 0x20

struc fat_oem_block

      oem:			resb	8
      bytes_per_sector:		resw	1
      sectors_per_cluster:	resb 	1
      reserved_sectors:		resw	1
      no_fats:			resb	1
      no_root_entries:		resw	1
      no_sectors:		resw	1
      media:			resb	1
      sectors_per_fat:		resw	1
      sectors_per_track:	resw	1
      heads_per_cylinder:	resw	1
      no_hidden_sectors:	resd	1
      no_large_sectors:		resd	1
      drive_number:		resb	1
      unused:			resb	1
      ext_boot_sig:		resb	1
      serial_number:		resd	1
      valume_label:		resb	11
      file_system:		resb 	8

endstruc

%ifndef STGONE

%define FAT12_OEMB_ADDR	0x0503

;;; Convert CHS to LBA
;;; LBA = (cluster - 2) * sectors per cluster

%macro CHS_TO_LBA 0
	sub ax, 0x0002						; zero base cluster number
	xor cx, cx
	mov cl, BYTE [FAT12_OEMB_ADDR+sectors_per_cluster] 	; convert byte to word
	mul cx
	add ax, WORD [.fdsect]
%endmacro
     
;;; Convert LBA to CHS
;;; AX=>LBA Address to convert
;;;
;;; absolute sector = (logical sector / sectors per track) + 1
;;; absolute head   = (logical sector / sectors per track) MOD number of heads
;;; absolute track  = logical sector / (sectors per track * number of heads)

%macro LBA_TO_CHS 0
	xor dx, dx						; prepare dx:ax for operation
	div WORD [FAT12_OEMB_ADDR+sectors_per_track]		; calculate
	inc dl                                  		; adjust for sector 0
	mov BYTE [.lf_dchs+sector], dl
	xor dx, dx						; prepare dx:ax for operation
	div WORD [FAT12_OEMB_ADDR+heads_per_cylinder]		; calculate
	mov BYTE [.lf_dchs+head], dl
	mov BYTE [.lf_dchs+cylinder], al
%endmacro

;;; Loads a file into memory using BIOS services
;;; Parameters:
;;; 1 - Pointer to the file name
;;; 2/3 - Address (Segment/Offset) where to load root dir & FAT
;;; 4/5 - Address (Segment/Offset) where to load file

load_file:	

	[section .data]

.fdsect:
	db 1
.lf_dchs:

	istruc dchs
		at drive,	db	0
		at cylinder,	db	0
		at head,	db	0
		at sector,	db	0
	iend
	
	__SECT__

.load_root:

;;     	pop ax
;;     	pop bx
;;     	pop cx
;;     	pop dx
;;    .kkk2:	jmp .kkk2
	RESERVE_LOCAL 2
	
	;; compute size in sectors of root directory and store in "cx"
	;; The size equation is ((sizeof directory entry) * (no of directory entries)) / (bytes per sector)
	xor cx, cx
	xor dx, dx
	mov ax, 0x0020 ; sizeof directory entry is 32-bits
	mul WORD [FAT12_OEMB_ADDR+no_root_entries]
	div WORD [FAT12_OEMB_ADDR+bytes_per_sector]
	;; If the divide left a remainder it should be in dx	
	or dx, dx 
	jz .continue_1
	inc ax
.continue_1:
	xchg ax, cx

	;; compute location of root directory and store in "ax"
	mov al, BYTE [FAT12_OEMB_ADDR+no_fats]		; number of FATs
	mul WORD [FAT12_OEMB_ADDR+sectors_per_fat]	; sectors used by FATs
	add ax, WORD [FAT12_OEMB_ADDR+reserved_sectors]	; adjust for reserved sectors
	
	;; compute the first data sector number	
	mov WORD [.fdsect], ax	; base of root directory
	add WORD [.fdsect], cx	; base of FAT
	
	;; read root directory into memory
	LBA_TO_CHS
	BIOS_READ_SECTORS GET_ARG(2), GET_ARG(3), cl, .lf_dchs, .err_handler

	;; browse root directory for binary image
	mov cx, WORD [FAT12_OEMB_ADDR+no_root_entries]	; loop counter
	mov di, GET_ARG(3)	; first root entry
.loop:
	CALL_PROC memcmp, GET_ARG(1), di, 0x000B
	test ax, 0x0001
	jnz .file_found
	;; not found in the entry, try next one
	add di, 0x0020
	loop .loop
	jmp .err_handler

.file_found:

	;; save starting cluster of boot image
	mov dx, WORD [di + 0x001A]
 	SET_LOCAL 1, dx
	
.load_fat:
     
	;; compute size of FAT and store in "cx"     
	xor ax, ax
	mov al, BYTE [FAT12_OEMB_ADDR+sectors_per_fat]
	mov cx, ax

	;; compute location of FAT and store in "ax"
	mov ax, WORD [FAT12_OEMB_ADDR+reserved_sectors]

	;; read FAT into memory
 	LBA_TO_CHS
 	BIOS_READ_SECTORS GET_ARG(2), GET_ARG(3), cl, .lf_dchs, .err_handler

	mov cx, GET_ARG(5)
	SET_LOCAL 2, cx

.load_image:

	mov ax, GET_LOCAL(1)
	CHS_TO_LBA
	LBA_TO_CHS
	BIOS_READ_SECTORS GET_ARG(4), GET_LOCAL(2), BYTE [FAT12_OEMB_ADDR+sectors_per_cluster] , .lf_dchs, .err_handler
	DUMP_STATE 'Read sector'
	;; increment load buffer pointer
	mov cx, GET_LOCAL(2)
        add cx, [FAT12_OEMB_ADDR+bytes_per_sector]
	SET_LOCAL 2, cx
	;; compute next cluster
	mov ax, GET_LOCAL(1)	  	; identify current cluster
	mov cx, ax              	; copy current cluster
	mov dx, ax              	; copy current cluster
	shr dx, 0x0001          	; divide by two
	add cx, dx              	; sum for (3/2)
	mov bx, GET_ARG(3)	 	; location of FAT in memory
	add bx, cx              	; index into FAT
	mov dx, WORD [bx]       	; read two bytes from FAT
	test ax, 0x0001
	jnz .handle_odd_cluster
          
.handle_even_cluster:
     
	and dx, 0000111111111111b	; take low twelve bits
	jmp .done
         
.handle_odd_cluster:
     
	shr dx, 0x0004			; take high twelve bits
          
.done:
     
 	SET_LOCAL 1, dx
	cmp dx, 0x0FF0			; test if the current FAT entry indicated the end of file
	jb .load_image

;;   	pop ax
;;   	pop bx
;;   	pop cx
;;   	pop dx
;;  .kkk:	jmp .kkk
	ret

.err_handler:
	[section .data]
.LF_ERR_MSG:	db 'Error loading file', 0x0
	__SECT__
	
	BIOS_SET_VIDEO_MODE MODE_640x350_16_COLOR_GRAPHICS
	CALL_PROC print, .LF_ERR_MSG, BIOS_COLOR(COLOR_BLACK, COLOR_RED)
	
.hang:
	jmp .hang
	

%endif
	
%endif