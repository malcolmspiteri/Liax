;; The loader will do the following tasks:
;; 	- Setup initial GDT and IDT
;; 	- Switch to 32-bit PMode
;; 	- Enable the A20 Gate
;; 	- Setup stack for the kernel
;; 	- Invoke the kernal at 0x10000
	
bits 16
org 0x2000

;;global start

%define BS_SIG_OFFSET_LO 0x0410	; Detected hardware
%define BS_SIG_OFFSET_HI 0x0420
%define KERNEL_SEG 0x1000
%define KERNEL_OFFSET 0x0000
%define GDT_CODE_SEGMENT_OFFSET 0x8
%define GDT_DATA_SEGMENT_OFFSET 0x10

section .text

	
	jmp start_stgtwo

includes:

%include "./src/loader/include/util.inc"
%include "./src/loader/include/bios.inc"
%include "./src/loader/include/stdio.inc"

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
	BIOS_SET_CURSOR_POSITION 0x0, 0x2, 0x1
	PRINT_STRING 'Enabling the A20 gate...'
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
	PRINT_STRING 'OK'
	;; Load the GDT
	BIOS_SET_CURSOR_POSITION 0x0, 0x3, 0x1
	PRINT_STRING 'Loading GDT'
	PRINT_STRING 'OK'
	;; Detect the amount of memory in the system
	;CALL_PROC detect_memory

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
  	BIOS_SET_CURSOR_POSITION 0x0, 0x0, 0x1
  	PRINT_STRING 'My OS'
  	pop si
  	pop fs
  	pop ax
  	ret

detect_memory:

	;; Get the amount of low memory first...useless but anyway
  	BIOS_SET_CURSOR_POSITION 0x0, 0x4, 0x1
	PRINT_STRING 'Low memory'
	;CALL_PROC get_lomem, lowmem_amt, failure
	;CALL_PROC word_to_ascii, lowmem_amt, lowmem_amt_txt, lowmem_amt_char
	;CALL_PROC write, HEX_ASCII_REP_PREFIX
	;CALL_PROC write, lowmem_amt_txt
	ret
	
switch_to_pmode:

	cli                     ; Disable interrupts
	xor ax, ax
	mov ds, ax              ; Set DS-register to 0 - used by lgdt
	lgdt [gdt_pointer]		; Load the GDT descriptor
	
	mov eax, cr0            
	or eax, 1               ; Set bit 0
	mov cr0, eax            ; Copy into CR0 to enable pmode

	push GDT_CODE_SEGMENT_OFFSET
	push pmode_start
	retf      				; Far jump to fix CS & IP


failure:
     
	PRINT_STRING 'ERROR'

die:

	jmp die

bits 32

;;extern _ld_main

pmode_start:

	;-------------------------------;
	;   Set registers		;
	;-------------------------------;

	mov	ax, GDT_DATA_SEGMENT_OFFSET		; set data segments to data selector (0x10) 
	mov	ds, ax
	mov	ss, ax
	mov	es, ax
	mov	fs, ax
	mov	esp, 0x90000		; stack begins from 90000h	
    mov byte [ds:0B8000h], 'P'      ; Move the ASCII-code of 'P' into first video memory
    mov byte [ds:0B8001h], 1Bh      ; Assign a color code
;; 	call KERNEL_OFFSET
	jmp die32

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
	
	;; call _ld_main	
  	
die32:	jmp die32
	
section .data

header_title db 'Liax Loader for x86', 0x0

;; Memory detection messages
lomem db 'Detecting low memory...', 0x0

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

;CRLF db 0x0D, 0x0A, 0x0
ok_msg db 'OK', 0x0
a20_msg db 'Enabling the A20 gate...', 0x0
load_gdt_act db 'Loading GDT...', 0x0
switch_to_pmode_act db 'Switching to 32-bit Protected Mode...', 0x0

PROGRESS_IND db '.', 0
ERROR_MSG 		db 'ERROR', 0
PE_FILENAME db 'KERNEL  EXE'
HEX_ASCII_REP_PREFIX db '0x', 0

section .bss

lowmem_amt resb 2
lowmem_amt_txt resb 5
lowmem_amt_char resb 1