;********************************************************************************
;* Name			: boot							*
;* Code model		: Real mode flat model					*
;* Version		: 1.0							*
;* Date			: 27/11/2009						*
;* Author		: Malcolm Spiteri					*
;* Description		: Melite Bootstrap. The bootstrap relocates itself	*
;*                        to another address and loads the the Melite Loader.	* 
;*                        It also sets up the stack which will be used by the	*
;*                        loader and kernel.                  			*
;********************************************************************************

bits 16	; Set 16 bit code generation
org 0x0	; We are loaded by BIOS at 0x07c0:0x0000

%define BOOT_SECTOR_SIZE 	0x200	; 512-bytes
%define INIT_SEG 		0x07C0	; This is where we start
%define RELOC_SEG 		0x0500 

; Stack setup defs. Just above the BIOS data area (BDA). Stack's range is 0x05000 to 0x09000 i.e. 16Kib
%define STACK_SEG 		0x0500					 
%define STACK_OFFSET 		0x3FFF

; Loading
%define ROOT_FAT_OFFSET 	0x0200	; Past bootstrap
%define LOADER_SEG 		0x0900	; Past stack
%define LOADER_OFFSET 		0x0000				

%define BOOT_DEVICE 		0x0	; Floppy
%define VOLUME_LABEL 		'MELITE', 0x20, 0x20, 0x20, 0x20, 0x20
%define FILE_SYSTEM 		'FAT12', 0x20, 0x20, 0x20

start:	
	jmp past_oem

; OEM Parameter block
BPB_OEM				db 'Melite  '
BPB_BYTES_PER_SECTOR:  		dw 512
BPB_SECTORS_PER_CLUSTER: 	db 1
BPB_NO_RES_SECTORS: 		dw 1
BPB_NO_FATS: 	    		db 2
BPB_ROOT_ENTRIES: 	    	dw 224
BPB_NO_SECTORS: 	    	dw 2880
BPB_MEDIA: 	            	db 0xF0
BPB_SECTORS_PER_FAT: 	    	dw 9
BPB_SECTORS_PER_TRACK: 		dw 18
BPB_HEADS_PER_CYLINDER: 	dw 2
bpbHiddenSectors: 	    	dd 0
bpbLargeSectors:     		dd 0
bsDriveNumber: 	        	db 0
bsUnused: 	            	db 0
bsExtBootSignature: 		db 0x29
bsSerialNumber:	        	dd 0x3ced2208
bsVolumeLabel: 	        	db VOLUME_LABEL
bsFileSystem: 	        	db FILE_SYSTEM

past_oem:

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

	;; *********************************************************
	;; Uses BIOS service 10/E to write on the screen
	;; *********************************************************
write:	
.start:
	lodsb          	; AL = [DS:SI]
	or al,al      	; Set zero flag if al=0
	jz .success 	; Jump to .success if zero flag is set
	mov ah,0x0E	; Video function 0Eh
	mov bx,0x0007	; Color
	int 0x10
	jmp .start	; Load characters until AL=0	
.success:
	ret

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

;************************************************;
; Reads a series of sectors
; CX=>Number of sectors to read
; AX=>Starting sector
; ES:BX=>Buffer to read to
;************************************************;

read_sectors:
.start:
	mov di, 0x0005                          ; five retries for error
.sector_loop:
	push ax
	push bx
	push cx
	call lba_to_chs                         ; convert starting sector to CHS
	mov ah, 0x02                            ; BIOS read sector
	mov al, 0x01                            ; read one sector
	mov ch, BYTE [ABS_TRACK]            	; track
	mov cl, BYTE [ABS_SECTOR]           	; sector
	mov dh, BYTE [ABS_HEAD]             	; head
	mov dl, BYTE [bsDriveNumber]            ; drive
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
	add bx, WORD [BPB_BYTES_PER_SECTOR]	; queue next buffer
	inc ax                                  ; queue next sector
	loop .start                             ; read next sector (this will loop [cx] times)
	ret

;************************************************;
; Convert CHS to LBA
; LBA = (cluster - 2) * sectors per cluster
;************************************************;

chs_to_lba:
	sub ax, 0x0002                      ; zero base cluster number
	mov cl, BYTE [BPB_SECTORS_PER_CLUSTER] ; convert byte to word
	xor cx, cx
	mul cx
	add ax, WORD [datasector]           ; base data sector
	ret
     
;************************************************;
; Convert LBA to CHS
; AX=>LBA Address to convert
;
; absolute sector = (logical sector / sectors per track) + 1
; absolute head   = (logical sector / sectors per track) MOD number of heads
; absolute track  = logical sector / (sectors per track * number of heads)
;
;************************************************;

lba_to_chs:
	xor dx, dx                              ; prepare dx:ax for operation
	div WORD [BPB_SECTORS_PER_TRACK]           ; calculate
	inc dl                                  ; adjust for sector 0
	mov BYTE [ABS_SECTOR], dl
	xor dx, dx                              ; prepare dx:ax for operation
	div WORD [BPB_HEADS_PER_CYLINDER]          ; calculate
	mov BYTE [ABS_HEAD], dl
	mov BYTE [ABS_TRACK], al
	ret

load_setup:

;----------------------------------------------------
; Load root directory table
;----------------------------------------------------

.load_root:
     
	mov si,CRLF
	call write

	; compute size of root directory and store in "cx"
     
	xor cx, cx
	xor dx, dx
	mov ax, 0x0020                  ; 32 byte directory entry
	mul WORD [BPB_ROOT_ENTRIES]     ; total size of directory
	div WORD [BPB_BYTES_PER_SECTOR] ; sectors used by directory
	xchg ax, cx
          
	; compute location of root directory and store in "ax"
     
	mov al, BYTE [BPB_NO_FATS]		; number of FATs
	mul WORD [BPB_SECTORS_PER_FAT]		; sectors used by FATs
	add ax, WORD [BPB_NO_RES_SECTORS] 	; adjust for bootsector
	mov WORD [datasector], ax         	; base of root directory
	add WORD [datasector], cx
          
	; read root directory into memory (RELOC_SEG:ROOT_FAT_OFFSET)
     
	mov bx, ROOT_FAT_OFFSET ; copy root dir above stack
	call read_sectors

	;----------------------------------------------------
	; Find loader
	;----------------------------------------------------

	; browse root directory for binary image
	mov cx, WORD [BPB_ROOT_ENTRIES] ; load loop counter
	mov di, ROOT_FAT_OFFSET         ; locate first root entry
.loop:
	push cx
	mov cx, 0x000B                  ; eleven character name
	mov si, PE_FILENAME             ; image name to find
	push di
	rep cmpsb                       ; test for entry match
	pop di
	je  load_fat
	pop cx
	add di, 0x0020                  ; queue next directory entry
	loop .loop
	jmp failure

	;----------------------------------------------------
	; Load FAT
	;----------------------------------------------------

load_fat:
     
	; save starting cluster of boot image
     
	mov si,CRLF
	call write
	mov dx, WORD [di + 0x001A]
	mov WORD [cluster], dx                  ; file's first cluster
          
	; compute size of FAT and store in "cx"
     
	xor ax, ax
	mov al, BYTE [BPB_NO_FATS]          ; number of FATs
	mul WORD [BPB_SECTORS_PER_FAT]             ; sectors used by FATs
	mov cx, ax

	; compute location of FAT and store in "ax"

	mov ax, WORD [BPB_NO_RES_SECTORS]       ; adjust for bootsector
          
	; read FAT into memory (RELOC_SEG:ROOT_FAT_OFFSET)

	mov bx, ROOT_FAT_OFFSET                  ; copy FAT above bootstrap
	call read_sectors

	; read image file into memory (LOADER_SEG:LOADER_OFFSET)
     
	mov si,CRLF
	call write
	mov ax, LOADER_SEG
	mov es, ax                              ; destination for image
	mov bx, LOADER_OFFSET                   ; destination for image
	push bx

;----------------------------------------------------
; Load Setup
;----------------------------------------------------

load_setup_img:
     
    mov  ax, WORD [cluster]                  ; cluster to read
    pop  bx                                  ; buffer to read into
    call chs_to_lba                          ; convert cluster to LBA
    xor  cx, cx
    mov  cl, BYTE [BPB_SECTORS_PER_CLUSTER]     ; sectors to read
    call read_sectors
    push bx
          
    ; compute next cluster
     
    mov ax, WORD [cluster]                  ; identify current cluster
    mov cx, ax                              ; copy current cluster
    mov dx, ax                              ; copy current cluster
    shr dx, 0x0001                          ; divide by two
    add cx, dx                              ; sum for (3/2)
    mov bx, ROOT_FAT_OFFSET			        ; location of FAT in memory
    add bx, cx                              ; index into FAT
    mov dx, WORD [bx]                       ; read two bytes from FAT
    test ax, 0x0001
    jnz .handle_odd_cluster
          
.handle_even_cluster:
     
    and dx, 0000111111111111b               ; take low twelve bits
    jmp .done
         
.handle_odd_cluster:
     
    shr dx, 0x0004                          ; take high twelve bits
          
.done:
     
    mov WORD [cluster], dx                  ; store new cluster
    cmp dx, 0x0FF0                          ; test if the current FAT entry indicated the end of file
    jb load_setup_img
          
jump_to_loader:
     
    mov si,CRLF
    call write
    push WORD LOADER_SEG					; Set the jump address on the stack and make a far return
    push WORD LOADER_OFFSET	
    retf
          
failure:
     
    mov si,ERROR_MSG
    call write
    mov ah, 0x00
    int 0x16                                ; await keypress
    int 0x19                                ; warm boot computer

     datasector  dw 0x0000
     cluster     dw 0x0000

CRLF 			db 0x0D, 0x0A, 0
LOADING_MSG 	db 'Melite is loading', 0
ERROR_MSG 		db 'ERROR', 0
PROGRESS_IND	db '.', 0

;Parameters used for loading the second stage boot loader
ABS_SECTOR	db 0x0
ABS_HEAD	db 0x0
ABS_TRACK	db 0x0 ; Analogous to a cyclinder
PE_FILENAME db 'MELOADERSYS'

times 510 - ($-$$) db 0					; We have to be 512 bytes. Clear the rest of the bytes with 0
dw 0xAA55								; Boot Signiture