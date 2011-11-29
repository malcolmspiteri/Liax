%ifndef _UTIL_INC
%define _UTIL_INC

%define LOCAL_OFFSET(p) p * 2

%define PARAM_OFFSET(p) p * 2

%macro GET_PARAM 1-2 ax
	mov %2, WORD[ss:bp+PARAM_OFFSET(%1)]
%endmacro

%define GET_ARG(n) WORD[ss:bp+PARAM_OFFSET(n)]

%define GET_LOCAL(n) WORD[ss:bp-LOCAL_OFFSET(n)]

%macro RESERVE_LOCAL 1
	pop bx			; return address
	mov ax, %1
	shl ax, 1
	sub sp, ax
	push bx	
%endmacro
	
%macro SET_LOCAL 2
 	%if %2 == ax
 		push bx
 		mov bx, %2
 		mov WORD [ss:bp-LOCAL_OFFSET(%1)], bx
 		pop bx
 	%else
 		push ax
 		mov ax, %2
 		mov WORD [ss:bp-LOCAL_OFFSET(%1)], ax
 		pop ax
 	%endif
%endmacro

%macro PUSH_ALL 0
	push ds
	push es
	push di
	push si
	push bp
	push dx
	push cx 
	push bx
%endmacro

%macro POP_ALL 0
	pop bx
	pop cx 	   
	pop dx
	pop bp
	pop si	   
	pop di
	pop es
	pop ds
%endmacro

%macro  PUSH_PARAMS 0-* 

	%rep %0
	%rotate -1 
       	push WORD %1 	
	%endrep 

%endmacro

%macro  POP_PARAMS 0-* 

	%rep %0
       	pop bx
	%endrep 

%endmacro

;; Macro pushes all general purpose registers on the stack, saves the caller's stack pointer, pushes parameters passed on the stack
;; and calls the procedure name passed in the first parameter
%macro CALL_PROC 1-2+
	PUSH_ALL
	PUSH_PARAMS %2
	push bp
	mov bp, sp
	call %1
	mov sp, bp
	pop bp
	POP_PARAMS %2
;; 	add sp, (%0 - 1) * 2
	POP_ALL
%endmacro

%endif