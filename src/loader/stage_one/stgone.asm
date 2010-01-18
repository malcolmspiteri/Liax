;********************************************************************************
;* Name			: stgone						*
;* Code model		: Real mode flat model					*
;* Version		: 1.0							*
;* Date			: 27/11/2009						*
;* Author		: Malcolm Spiteri					*
;* Description		: System Bootstrap. The bootstrap relocates itself	*
;*                        to another address and loads the the Melite Loader.	* 
;*                        It also sets up the stack which will be used by the	*
;*                        loader and kernel.                  			*
;********************************************************************************

bits 16	; Set 16 bit code generation
org 0x0	; We are loaded by BIOS at 0x07c0:0x0000

%define BOOT_SECTOR_SIZE 	0x0200	; 512-bytes
%define INIT_SEG 		0x07C0	; This is where we start
%define RELOC_SEG 		0x0050

;; Stack setup defs. Just above the BIOS data area (BDA). Stack's range is 0x00700 to 0x00B00 = 1 Kib
%define STACK_SEG 		0x0070
%define STACK_OFFSET 		0x0400

;; Loading
%define ROOT_FAT_OFFSET 	0x0600	; Past stack
%define STGTWO_SEG 		0x0000
%define STGTWO_OFFSET 		0x3000				

%define BOOT_DEVICE 		0x0	; Floppy
%define VOLUME_LABEL 		'MELITE', 0x20, 0x20, 0x20, 0x20, 0x20

%include "./src/loader/include/fat.inc"
%include "./src/loader/include/fat12.inc"

start:	
	jmp post_oem

oemb:

istruc fat_oem_block

      at oem,			db	'Melite  '
      at bytes_per_sector,	dw 	512
      at sectors_per_cluster,	db	1
      at reserved_sectors,	dw	1
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
	;Relocate the bootstrap to RELOC_SEG
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

real_start:

	call setup_stack
	mov si,LOADING_MSG
	call write
	call load_setup
	
	; Should never arrive here
hang: 	jmp hang

%include "./src/loader/include/biosvid.inc"
%include "./src/loader/include/biosdio.inc"

	;; *********************************************************
	;; Setup a stack
	;; *********************************************************
	
setup_stack:
	cli			; clear interupts
	mov ax,STACK_SEG
	mov ss,ax		; Stack is in the same segment
	mov sp,STACK_OFFSET
	sti			; start interupts
	ret

;************************************************
; Loads a file into memory using BIOS services
;************************************************
load_setup:

;----------------------------------------------------
; Load root directory table
;----------------------------------------------------

.load_root:

	mov si,CRLF
	call write

	; compute size in sectors of root directory and store in "cx"
	; The size equation is ((sizeof directory entry) * (no of directory entries)) / (bytes per sector)

	xor cx, cx
	xor dx, dx
	mov ax, 0x0020                  
	mul WORD [oemb+no_root_entries]
	div WORD [oemb+bytes_per_sector]
	; If the divide left a remainder it should be in dx	
	or dx, dx 
	jz .continue_1
	inc ax
.continue_1:
	xchg ax, cx

	; compute location of root directory and store in "ax"

	mov al, BYTE [oemb+no_fats]				; number of FATs
	mul WORD [oemb+sectors_per_fat]			; sectors used by FATs
	add ax, WORD [oemb+reserved_sectors] 	; adjust for bootsector
	
	; compute the first data sector number
	
	mov WORD [stgtwo_dchs+datasector], ax	; base of root directory
	add WORD [stgtwo_dchs+datasector], cx	; base of FAT

	; read root directory into memory (RELOC_SEG:ROOT_FAT_OFFSET)

	mov bx, ROOT_FAT_OFFSET ; copy root dir above stack
	call read_sectors

	;----------------------------------------------------
	; Find stage two image
	;----------------------------------------------------

	; browse root directory for binary image
	mov cx, WORD [oemb+no_root_entries] ; load loop counter
	mov di, ROOT_FAT_OFFSET         ; locate first root entry
.loop:
	push cx
	mov cx, 0x000B                  ; eleven character name
	mov si, PE_FILENAME             ; image name to find
	push di
	rep cmpsb                       ; test for entry match
	pop di
	je  .file_found
	pop cx
	add di, 0x0020                  ; queue next directory entry
	loop .loop
	jmp failure

.file_found:

	; save starting cluster of boot image

	mov dx, WORD [di + 0x001A]
	mov WORD [stgtwo_dchs+cluster], dx                  ; file's first cluster

	;----------------------------------------------------
	; Load FAT
	;----------------------------------------------------

.load_fat:
     
	mov si,CRLF
	call write
          
	; compute size of FAT and store in "cx"
     
	xor ax, ax
;	mov al, BYTE [oemb+no_fats]          ; number of FATs
;	mul WORD [oemb+sectors_per_fat]      ; sectors used by FATs
	mov al, BYTE [oemb+sectors_per_fat]
	mov cx, ax

	; compute location of FAT and store in "ax"

	mov ax, WORD [oemb+reserved_sectors]       ; adjust for bootsector
          
	; read FAT into memory (RELOC_SEG:ROOT_FAT_OFFSET)

	mov bx, ROOT_FAT_OFFSET                  ; copy FAT above bootstrap
	call read_sectors

	; read image file into memory (STGTWO_SEG:STGTWO_OFFSET)
     
	mov si,CRLF
	call write
	mov ax, STGTWO_SEG						; destination for image
	mov es, ax                              
	mov bx, STGTWO_OFFSET                   ; destination for image
	push bx

.load_image:
     
    mov  ax, WORD [stgtwo_dchs+cluster]                  ; cluster to read
    pop  bx                                  ; buffer to read into
    call chs_to_lba                          ; convert cluster to LBA
    xor  cx, cx
    mov  cl, BYTE [oemb+sectors_per_cluster]     ; sectors to read
    call read_sectors
    push bx
          
    ; compute next cluster
     
    mov ax, WORD [stgtwo_dchs+cluster]  ; identify current cluster
    mov cx, ax              ; copy current cluster
    mov dx, ax              ; copy current cluster
    shr dx, 0x0001          ; divide by two
    add cx, dx              ; sum for (3/2)
    mov bx, ROOT_FAT_OFFSET ; location of FAT in memory
    add bx, cx              ; index into FAT
    mov dx, WORD [bx]       ; read two bytes from FAT
    test ax, 0x0001
    jnz .handle_odd_cluster
          
.handle_even_cluster:
     
    and dx, 0000111111111111b               ; take low twelve bits
    jmp .done
         
.handle_odd_cluster:
     
    shr dx, 0x0004                          ; take high twelve bits
          
.done:
     
    mov WORD [stgtwo_dchs+cluster], dx                  ; store new cluster
    cmp dx, 0x0FF0                          ; test if the current FAT entry indicated the end of file
    jb .load_image

jump_to_stgtwo:
     
    mov si,CRLF
    call write
    push WORD STGTWO_SEG					; Set the jump address on the stack and make a far return
    push WORD STGTWO_OFFSET	
    retf

;************************************************
; Reads a series of sectors
; CX=>Number of sectors to read
; AX=>Starting sector
; ES:BX=>Buffer to read to
;************************************************

read_sectors:
.start:
	mov di, READ_SECTORS_RETRIES			; five retries for error
.sector_loop:
	push ax
	push bx
	push cx
	call lba_to_chs                         ; convert starting sector to CHS
	mov ah, 0x02                            ; BIOS read sector
	mov al, 0x01                            ; read one sector
	mov ch, BYTE [stgtwo_dchs+cylinder]     ; cylinder
	mov cl, BYTE [stgtwo_dchs+sector]       ; sector
	mov dh, BYTE [stgtwo_dchs+head]         ; head
	mov dl, BYTE [stgtwo_dchs+drive]        ; drive
	int 0x13                                ; invoke BIOS
	jnc .success                            ; test for read error
	xor ax, ax                              ; BIOS reset disk
	int 0x13                                ; invoke BIOS
	dec di                                  ; decrement error counter
	pop cx
	pop bx
	pop ax
	jnz .sector_loop			; attempt to read again
	int 0x18
.success:
	mov si,PROGRESS_IND
	call write
	pop cx
	pop bx
	pop ax
	add bx, WORD [oemb+bytes_per_sector]	; queue next buffer
	inc ax                                  ; queue next sector
	loop .start                             ; read next sector (this will loop [cx] times)
	ret

;************************************************
; Convert CHS to LBA
; LBA = (cluster - 2) * sectors per cluster
;************************************************

chs_to_lba:
	sub ax, 0x0002 ; zero base cluster number
	xor cx, cx
	mov cl, BYTE [oemb+sectors_per_cluster] ; convert byte to word
	mul cx
	add ax, WORD [stgtwo_dchs+datasector] ; base data sector
	ret
     
;************************************************
; Convert LBA to CHS
; AX=>LBA Address to convert
;
; absolute sector = (logical sector / sectors per track) + 1
; absolute head   = (logical sector / sectors per track) MOD number of heads
; absolute track  = logical sector / (sectors per track * number of heads)
;
;************************************************

lba_to_chs:
	xor dx, dx                              ; prepare dx:ax for operation
	div WORD [oemb+sectors_per_track]       ; calculate
	inc dl                                  ; adjust for sector 0
	mov BYTE [stgtwo_dchs+sector], dl
	xor dx, dx                              ; prepare dx:ax for operation
	div WORD [oemb+heads_per_cylinder]       ; calculate
	mov BYTE [stgtwo_dchs+head], dl
	mov BYTE [stgtwo_dchs+cylinder], al
	ret

failure:
     
    mov si,ERROR_MSG
    call write
    mov ah, 0x00
    int 0x16                                ; await keypress
    int 0x19                                ; warm boot computer

CRLF 			db 0x0D, 0x0A, 0
PROGRESS_IND	db '.', 0
LOADING_MSG 	db 'Melite is loading', 0
ERROR_MSG 		db 'ERROR', 0

;Parameters used for loading the second stage boot loader
stgtwo_dchs:

istruc dchs
	  at drive,			db	0x0
	  at cylinder,		db	0x0
      at head,			db	0x0
      at sector,		db 	0x0
      at datasector,  dw 0x0000
      at cluster,     dw 0x0000
iend

PE_FILENAME db 'MELOADERSYS'

times 510 - ($-$$) db 0					; We have to be 512 bytes. Clear the rest of the bytes with 0
dw 0xAA55								; Boot Signiture