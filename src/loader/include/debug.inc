%ifndef _DEBUG_INC
%define _DEBUG_INC

%ifndef _UTIL_INC
%include "./src/loader/include/util.inc"
%endif

%ifndef _UTIL_INC
%include "./src/loader/include/stdio.inc"
%endif

%macro DUMP_STATE 1
	PUSH_ALL
	push ax
	PRINT_LINE %1
	;; AX
	PRINT_STRING 'ax='
	CALL_PROC word_to_ascii, ax
	PRINT_STRING ax
	;; BX
	PRINT_STRING ' bx='
	CALL_PROC word_to_ascii, bx
	PRINT_STRING ax
	;; CX
	PRINT_STRING ' cx='
	CALL_PROC word_to_ascii, cx
	PRINT_STRING ax
	;; DX
	PRINT_STRING ' dx='
	CALL_PROC word_to_ascii, dx
	PRINT_STRING ax
	PRINT_LINE ' '
	pop ax
	POP_ALL
%endmacro

%endif