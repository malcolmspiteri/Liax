  [BITS 16]          ; Set 16 bit code generation
  [ORG 0100H]        ; Set code start address to 100h (COM file)

  [SECTION .text]    ; Section containing code
  START:
	;Relocate
	mov	ax,cs
	mov	ds,ax
	mov	ax,0x14b3
	mov	es,ax
	mov	cx,0x100
	mov	si,0x100
	xor	di,0x100
	rep
	movsw
	jmp 0x14b3:.continue_start
.continue_start:
	mov ax,0x14b3		
	mov ds,ax				; Set the data segment to the new location
	mov si,loading_msg		; Print message
    call show_msg	

hang: jmp hang
	
; Print a 0-terminated string on the screen
show_msg:

    lodsb           ; AL = [DS:SI]
    or al,al        ; Set zero flag if al=0
    jz .done        ; Jump to .done if zero flag is set
    mov ah, 0x0E	; Video function 0Eh
    mov bx, 0x0007	; Color
    int 0x10
    jmp show_msg	; Load characters until AL=0
.done:
    retn
		
	loading_msg   db 'MelitaOS is loading...', 0 ;Here's our message
