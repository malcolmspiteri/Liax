;; The loader will do the following tasks:
;; 	- Setup initial GDT and IDT
;; 	- Switch to 32-bit PMode
;; 	- Enable the A20 Gate
;; 	- Setup stack for the kernel
;; 	- Load the kernal at 0x100000 (past BIOS ROM)
	
bits 16
;;org 0x0

global start

%include "./src/loader/include/bios_utils.mac"

%define BS_SIG_OFFSET_LO 0x0410	; Detected hardware
%define BS_SIG_OFFSET_HI 0x0420

section .text

start:
	; make sure ds and es == cs
	mov ax, cs
	mov ds, ax
	mov es, ax
	CLEAR_SCREEN
	call draw_header
	
;; Determine if A20 gate is enabled by reading the BDA detected
;; hardware WORD from  segments 0x0000 and 0xFFFF and comparing them
	
.handleA20:
	;; Get the value of the WORD @ 0x0000:BS_ID_OFFSET and store it in BX
	SET_CURSOR_POS 0x0, 0x2, 0x1
	WRITE a20_msg		
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
	WRITE ok_msg
	;; Load the GDT
	SET_CURSOR_POS 0x0, 0x3, 0x1
	WRITE load_gdt_act
	call load_gdt
	WRITE ok_msg

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
	SET_CURSOR_POS 0x0, 0x0, 0x1
	WRITE msg
	pop si
	pop fs
	pop ax
	ret

load_gdt:

	cli
	pusha
	lgdt [gdt_pointer]		; load GDT into GDTR
	sti
	popa
	ret

switch_to_pmode:

init_complete:

bits 32

hlt ; halt the CPU
  	
section .data

msg db 'Melite Loader'
msg_end db 0x0
CRLF db 0x0D, 0x0A, 0x0
ok_msg db 'OK', 0x0
a20_msg db 'Enabling the A20 gate...', 0x0
load_gdt_act db 'Loading GDT...', 0x0
switch_to_pmode_act db 'Switching to 32-bit Protected Mode...', 0x0

gdt_table:	

; Mandatory null descriptor 
	dd 0 				
	dd 0 

; Code descriptor:
	
	dw 0FFFFh 			; limit low
	dw 0 				; base low
	db 0 				; base middle
	db 10011010b 			; access
	db 11001111b 			; granularity
	db 0 				; base high

; Data descriptor:
	
	dw 0FFFFh 			; limit low (Same as code)
	dw 0 				; base low
	db 0 				; base middle
	db 10010010b 			; access
	db 11001111b 			; granularity
	db 0				; base high
	
end_of_gdt:

gdt_pointer:
	dw end_of_gdt - gdt_table - 1 	; limit (Size of GDT)
	dd gdt_table 			; base of GDT

section .bss