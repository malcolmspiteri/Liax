%ifndef _UTIL_INC
%define _UTIL_INC

%define PARAM_OFFSET(p) p*2

%macro GET_PARAM 1-2 ax
	mov %2, WORD[ss:bp-PARAM_OFFSET(%1)]
%endmacro

%macro PARAM_TO_MEM 2
	push ax
	mov ax, WORD[ss:bp-PARAM_OFFSET(%1)]
	mov %2, ax
	pop ax
%endmacro

%macro SP_TO_BP 0
    mov bx, sp
    mov bp, bx
%endmacro

%macro BP_TO_SP 0
    mov bx, bp
    mov sp, bx
%endmacro

%macro PUSH_ALL 0
    push di
	push si
	push bp
	push dx
	push cx 
	push ax
	push bx
%endmacro

%macro POP_ALL 0
	pop bx
    pop ax
	pop cx 	   
	pop dx
	pop bp
	pop si	   
	pop di
%endmacro

;; Macro pushes all general purpose registers on the stack, saves the caller's stack pointer, pushes parameters passed on the stack
;; and calls the procedure name passed in the first parameter
%macro CALL_PROC 1-2+
	PUSH_ALL
    SP_TO_BP
	pop bx 		; These to lines are necessary to restore the value of bx after the
	push bx		; invocation of SP_TO_BP
    PUSH_PARAMS %2
    call %1
    BP_TO_SP
	POP_ALL
%endmacro

%macro  PUSH_PARAMS 0-* 

  %rep  %0 
        push    %1 
  %rotate 1 
  %endrep 

%endmacro

; Converts a word to its ascii representation and writes to a given memory location along with a terminating character 0x0
word_to_ascii:

	; Parameter 1 - the address of the word to be converted
	GET_PARAM 1, bx 			
	mov dx, WORD[bx]	; set dx to the value of the word to convert
	; Parameter 2 - the address where the final converted word will be written
	GET_PARAM 2, bx
	mov di, bx
	; Parameter 3 - the address where converted chars will be temporarily held
	GET_PARAM 3, bx	 			
	; From right to left
	; 1st character
	CALL_PROC hex_to_ascii, dx, bx
	mov al, BYTE[bx]
	mov BYTE [di+3], al
	; 2nd character
	ror dx, 0x4
	CALL_PROC hex_to_ascii, dx, bx
	mov al, BYTE[bx]
	mov BYTE [di+2], al	
	; 3rd character
	ror dx, 0x4
	CALL_PROC hex_to_ascii, dx, bx
	mov al, BYTE[bx]
	mov BYTE [di+1], al
	; 4th character
	ror dx, 0x4
	CALL_PROC hex_to_ascii, dx, bx
	mov al, BYTE[bx]
	mov BYTE [di], al
	; Write terminating char
	mov BYTE [di+4], BYTE 0x0
	mov ax, WORD[di]
.success:
	ret

; Converts value of the low order nibble of DL to its ascii representation and stores in al
hex_to_ascii:

	GET_PARAM 1, dx
	GET_PARAM 2, bx
	and dx,0x000F ; Clear out HOB and LOB's HON
	mov ax,dx
	cmp al,0xA
	jae .alphabet_char
.numeric_char:
	; In this case we just add 0x30
	add al,0x30
	jmp .end
.alphabet_char:
	add al,0x37 ; 'A' char code is 0x41 but since our value is at minimum 0xA we need to take that into account
.end:
	mov BYTE [bx], al
	ret

%endif