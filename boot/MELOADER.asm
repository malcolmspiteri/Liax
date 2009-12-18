bits 16
org 0x0

%include "bios_utils.mac"

section .text

start:
	; clear registers
	xor ax,ax
	xor bx,bx
	xor cx,cx
	xor dx,dx	
	xor si,si
	xor di,di	
	; make sure ds and es == cs
	mov ax, cs
	mov ds, ax
	mov es, ax
	SET_PRE_ISR_HOOK 0x24, word [old_kb_int_seg], word [old_kb_int_off], ds, hello_pp
	CLEAR_SCREEN
	call show_banner3
	WRITE msg
	
	
hang:	jmp hang

; This call will fill up the first row of page 0, cols 0-79 with a red background
show_banner3:
.init:
	mov ax,0xb800
	mov fs,ax
	mov ax,0x0
.loop:
	mov si,ax
	mov word [fs:si],0xDB44
	cmp ax,0xA0 
	jnb .done   
	inc ax
	jmp .loop
.done:
	ret


;AL = character to display.
;BH = page number.
;BL = attribute.
;CX = number of times to write character.
show_banner2:
	; Move fs to BDA
	mov ax,0x0040
	mov fs,ax
	; Get the number of columns
	mov di,0x004A 	
	mov cx,WORD [fs:di] 	; Store no of cols in cl
	;dec cx
	; Write char at cursor
	mov al,0xDB
	mov bh,0x0
    mov bl,0x04						; Color
    mov ah,0x09						; Video function 9
    int 0x10	

	mov al, 1
	mov bh, 0
	mov bl, 0100_1110b ; red_yellow
	mov cx, msg_end - msg ;0x0018 ; length
	mov dl, 1 ;col
	mov dh, 0 ;row
	push cs
	pop es
	mov bp, msg
	mov ah, 13h
	int 10h
	ret

show_banner:
.start:
	xor ax,ax
	xor bx,bx
	xor cx,cx
	xor dx,dx
	xor si,si	
	; Set video mode
	mov al, 0x03
	mov ah, 0x0
	int 10h	
	; Move fs to BDA
	mov ax,0x0040
	mov fs,ax
	; Get the number of columns
	mov di,0x004A 	
	mov cx,WORD [fs:di] 	; Store no of cols in cl
	dec cl
.loop:
	; Move cursor to row 0 and col cl
	mov bh,0x0   		; current page. 
	mov dh,0x0   		; row. 
	mov dl,cl	  		; col. 
	mov ah,0x02			; BIOS function
	int 0x10
	; Write char at cursor
	mov al,0xDB
    mov ah,0x09						; Video function 9
    mov bl,0x40						; Color
    int 0x10	
	; Check if we're done else loop
	or cl,cl	
	jz .success
	dec cl
	jmp .loop	
.success:
	ret
	

hello_pp:
	WRITE hello_msg
	in	al,0x60	
	mov byte [pressed_key], al
	WRITE_LINE pressed_key	
	push word [old_kb_int_seg]
	push word [old_kb_int_off]
	retf
	
section .data

msg db 'Welcome to Melite Loader'
msg_end db 0x0
hello_msg db 'You pressed', 0x0
CRLF db 0x0D, 0x0A, 0x0
kuku db 'A'

section .bss

old_kb_int_seg resw 1
old_kb_int_off resw 1
pressed_key resb 1
