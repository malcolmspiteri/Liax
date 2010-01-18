;; The loader will do the following tasks:
;; 	- Setup initial GDT and IDT
;; 	- Switch to 32-bit PMode
;; 	- Enable the A20 Gate
;; 	- Setup stack for the kernel
;; 	- Load the kernal at 0x100000 (past BIOS ROM)
	
bits 16
org 0x3000

;;global start

%define BS_SIG_OFFSET_LO 0x0410	; Detected hardware
%define BS_SIG_OFFSET_HI 0x0420
%define OEMB_ADDR 0x0503 ; The location of the OEM block
%define ROOT_FAT_OFFSET 0x0B00	; Same location stage one uses
%define KERNEL_SEG 0x0000
%define KERNEL_OFFSET 0x9000

section .text

	jmp start_stgtwo

includes:

%include "./src/loader/include/util.inc"
%include "./src/loader/include/biosvid.inc"
%include "./src/loader/include/biosdio.inc"
%include "./src/loader/include/fat.inc"
%include "./src/loader/include/fat12.inc"
%include "./src/loader/include/bios_utils.mac"

start_stgtwo:

	; make sure ds = es = cs
	mov ax, cs
	mov ds, ax
	mov es, ax
	CALL_PROC clear_screen
	call draw_header
	
;; Determine if A20 gate is enabled by reading the BDA detected
;; hardware WORD from segments 0x0000 and 0xFFFF and comparing them
	
.handleA20:
	;; Get the value of the WORD @ 0x0000:BS_ID_OFFSET and store it in BX
	CALL_PROC set_cursor, 0x0, 0x2, 0x1
	CALL_PROC write, a20_msg		
	mov ax, 0x0
	mov fs, ax
	mov ax, BS_SIG_OFFSET_LO
	mov si, ax
	mov bx, WORD [fs:si]
	;; Ok now we change the segment to 0xFFFF, read the WORD at that location and store in DX
	mov ax, 0xffff
	mov fs, ax
	mov ax, BS_SIG_OFFSET_HI
	mov dx, WORD [fs:si]
	;; Compare the 2 WORDs in BX & CX
	test bx, dx
	jne enableA20
	CALL_PROC write, ok_msg
	;; Load the GDT
	CALL_PROC set_cursor, 0x0, 0x3, 0x1
	CALL_PROC write, load_gdt_act
	CALL_PROC write, ok_msg

load_kernel:

;----------------------------------------------------
; Load root directory table
;----------------------------------------------------

.load_root:

	CALL_PROC write, CRLF

	; compute size in sectors of root directory and store in "cx"
	; The size equation is ((sizeof directory entry) * (no of directory entries)) / (bytes per sector)

	xor cx, cx
	xor dx, dx
	mov ax, 0x0020                  
	mul WORD [OEMB_ADDR+no_root_entries]
	div WORD [OEMB_ADDR+bytes_per_sector]
	; If the divide left a remainder it should be in dx	
	or dx, dx 
	jz .continue_1
	inc ax
.continue_1:
	xchg ax, cx

	; compute location of root directory and store in "ax"

	mov al, BYTE [OEMB_ADDR+no_fats]				; number of FATs
	mul WORD [OEMB_ADDR+sectors_per_fat]			; sectors used by FATs
	add ax, WORD [OEMB_ADDR+reserved_sectors] 	; adjust for bootsector
	
	; compute the first data sector number
	
	mov WORD [kernel_dchs+datasector], ax	; base of root directory
	add WORD [kernel_dchs+datasector], cx	; base of FAT

	; read root directory into memory (RELOC_SEG:ROOT_FAT_OFFSET)

	mov bx, ROOT_FAT_OFFSET ; copy root dir above stack
	call read_sectors

	;----------------------------------------------------
	; Find stage two image
	;----------------------------------------------------

	; browse root directory for binary image
	mov cx, WORD [OEMB_ADDR+no_root_entries] ; load loop counter
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
	mov WORD [kernel_dchs+cluster], dx                  ; file's first cluster

	;----------------------------------------------------
	; Load FAT
	;----------------------------------------------------

.load_fat:
     
	CALL_PROC write, CRLF
          
	; compute size of FAT and store in "cx"
     
	xor ax, ax
	mov al, BYTE [OEMB_ADDR+sectors_per_fat]
	mov cx, ax

	; compute location of FAT and store in "ax"

	mov ax, WORD [OEMB_ADDR+reserved_sectors]       ; adjust for bootsector
          
	; read FAT into memory (RELOC_SEG:ROOT_FAT_OFFSET)

	mov bx, ROOT_FAT_OFFSET                  ; copy FAT above bootstrap
	call read_sectors

	; read image file into memory (STGTWO_SEG:STGTWO_OFFSET)
     
	CALL_PROC write, CRLF
	mov ax, KERNEL_SEG						; destination for image
	mov es, ax                              
	mov bx, KERNEL_OFFSET                   ; destination for image
	push bx

.load_image:
     
    mov  ax, WORD [kernel_dchs+cluster]                  ; cluster to read
    pop  bx                                  ; buffer to read into
    call chs_to_lba                          ; convert cluster to LBA
    xor  cx, cx
    mov  cl, BYTE [OEMB_ADDR+sectors_per_cluster]     ; sectors to read
    call read_sectors
    push bx
          
    ; compute next cluster
     
    mov ax, WORD [kernel_dchs+cluster]  ; identify current cluster
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
     
    mov WORD [kernel_dchs+cluster], dx                  ; store new cluster
    cmp dx, 0x0FF0                          ; test if the current FAT entry indicated the end of file
    jb .load_image

	CALL_PROC switch_to_pmode

hang:	jmp hang

enableA20:

	ret

;; Set the first row of page 0 to red background with yellow foreground
;; and write header message
	
draw_header:
.init:
 	push ax
  	push fs
  	push si
  	mov ax,0xb800
  	mov fs,ax
  	mov ax,0x0
.loop:
  	mov si,ax
  	mov word [fs:si],0x4E00
  	cmp ax,0x9E 
  	je .done
  	add ax, 0x2
  	jmp .loop
.done:
  	CALL_PROC set_cursor, 0x0, 0x0, 0x1
  	CALL_PROC write,  header_title
  	pop si
  	pop fs
  	pop ax
  	ret

switch_to_pmode:

    cli                     ; Disable interrupts
    xor ax, ax
    mov ds, ax              ; Set DS-register to 0 - used by lgdt
    lgdt [gdt_pointer]	; Load the GDT descriptor
	
    mov eax, cr0            
    or eax, 1               ; Set bit 0
    mov cr0, eax            ; Copy into CR0 to enable pmode

	push 0x8
	push pmode_start
    retf      		; Far jump to fix CS & IP


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
	mov ch, BYTE [kernel_dchs+cylinder]     ; cylinder
	mov cl, BYTE [kernel_dchs+sector]       ; sector
	mov dh, BYTE [kernel_dchs+head]         ; head
	mov dl, BYTE [kernel_dchs+drive]        ; drive
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
	CALL_PROC write, PROGRESS_IND
	pop cx
	pop bx
	pop ax
	add bx, WORD [OEMB_ADDR+bytes_per_sector]	; queue next buffer
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
	mov cl, BYTE [OEMB_ADDR+sectors_per_cluster] ; convert byte to word
	mul cx
	add ax, WORD [kernel_dchs+datasector] ; base data sector
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
	div WORD [OEMB_ADDR+sectors_per_track]       ; calculate
	inc dl                                  ; adjust for sector 0
	mov BYTE [kernel_dchs+sector], dl
	xor dx, dx                              ; prepare dx:ax for operation
	div WORD [OEMB_ADDR+heads_per_cylinder]       ; calculate
	mov BYTE [kernel_dchs+head], dl
	mov BYTE [kernel_dchs+cylinder], al
	ret

failure:
     
    CALL_PROC write, ERROR_MSG

bits 32

;;extern _ld_main

pmode_start:

	;-------------------------------;
	;   Set registers		;
	;-------------------------------;

	mov	ax, 0x10		; set data segments to data selector (0x10)
	mov	ds, ax
	mov	ss, ax
	mov	es, ax
	mov	fs, ax
	mov	esp, 0x90000		; stack begins from 90000h	
    mov byte [ds:0B8000h], 'P'      ; Move the ASCII-code of 'P' into first video memory
    mov byte [ds:0B8001h], 1Bh      ; Assign a color code
	call KERNEL_OFFSET

	%define IMAGE_PMODE_BASE 0x9000	
	mov    ebx, [IMAGE_PMODE_BASE+60]	; e_lfanew is a 4 byte offset address of the PE header; it is 60th byte. Get it
	add    ebx, IMAGE_PMODE_BASE 		; add base
	; EBX now points to beginning of _IMAGE_FILE_HEADER. Jump over it to the next section (_IMAGE_OPTIONAL_HEADER)
	add	ebx, 24
	mov	eax, [ebx]		; _IMAGE_FILE_HEADER is 20 bytes + size of sig (4 bytes)
	add	ebx, 16			; address of entry point is now in ebx	
	
     mov ebp, dword [ebx] ; store entry point address 
	 add ebx, 12 ; ImageBase member is 12 bytes from AddressOfEntryPoint member 
	 mov eax, dword [ebx] ; gets image base 
	 add ebp, eax ; add image base to entry point address

    ;call ebp ; Execute Kernel
die: 	jmp die
	
	;; call _ld_main	
  	
section .data

header_title db 'Melite Loader', 0x0

gdt:                    ; Address for the GDT

gdt_null:               ; Null Segment
        dd 0
        dd 0

gdt_code:               ; Code segment, read/execute, nonconforming
        dw 0FFFFh
        dw 0
        db 0
        db 10011010b
        db 11001111b
        db 0

gdt_data:               ; Data segment, read/write, expand down
        dw 0FFFFh
        dw 0
        db 0
        db 10010010b
        db 11001111b
        db 0

gdt_end:                ; Used to calculate the size of the GDT

gdt_pointer:
	dw gdt_end - gdt - 1 	; limit (Size of GDT)
	dd gdt 			; base of GDT

CRLF db 0x0D, 0x0A, 0x0
ok_msg db 'OK', 0x0
a20_msg db 'Enabling the A20 gate...', 0x0
load_gdt_act db 'Loading GDT...', 0x0
switch_to_pmode_act db 'Switching to 32-bit Protected Mode...', 0x0

;Parameters used for loading the kernel image

kernel_dchs:

istruc dchs
	  at drive,			db	0x0
	  at cylinder,		db	0x0
      at head,			db	0x0
      at sector,		db 	0x0
      at datasector,  dw 0x0000
      at cluster,     dw 0x0000
iend

PROGRESS_IND db '.', 0
ERROR_MSG 		db 'ERROR', 0
PE_FILENAME db 'KERNEL  EXE'

section .bss