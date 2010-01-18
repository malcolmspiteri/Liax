%ifndef _UTIL_INC
%define _UTIL_INC

%define PARAM_OFFSET(p) p*2

%macro GET_PARAM 1-2 ax
	mov %2, WORD[ss:bp-PARAM_OFFSET(%1)]
%endmacro

;; Macro pushes all general purpose registers on the stack, saves the caller's stack pointer, pushes parameters passed on the stack
;; and calls the procedure name passed in the first parameter
%macro CALL_PROC 1-2+

       pusha
       mov bx, sp
       mov bp, bx ;; This will point the procedure to the passed parameters and will also be used to restore the stack pointer after return
       PUSH_PARAMS %2
       call %1
       mov bx, bp
       mov sp, bx
       popa

%endmacro

%macro  PUSH_PARAMS 0-* 

  %rep  %0 
        push    %1 
  %rotate 1 
  %endrep 

%endmacro

%endif