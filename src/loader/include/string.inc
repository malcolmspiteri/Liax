%ifndef _STRING_INC
%define _STRING_INC

%ifndef _UTIL_INC
%include "./src/loader/include/util.inc"
%endif

;;; Copy a portion of memory from one address to another
;;; ParametersL
;;; 1/2 - Pointer to source address
;;; 3/4 - Pointer to destination address
;;; 5   - Size in bytes of the memory portion to copy
memcpy:
	mov ax,GET_ARG(1)
	mov ds,ax
	mov si,GET_ARG(2)
	mov ax,GET_ARG(3)
	mov es,ax
	mov di,GET_ARG(4)
	mov cx,GET_ARG(5)
	cld ; Clear the direction flag so that index registers are incremented
	repne 
	movsb	
	
;;; Compare two strings
;;; Parameters:
;;; 1 - Pointer to first string
;;; 2 - Pointer to second string
;;; 3 - Number of bytes to compare
;;; Returns:
;;; 1 if string match, 0 if they don't

memcmp:
	mov si, GET_ARG(1)
	mov di, GET_ARG(2)
	mov cx, GET_ARG(3)
	rep cmpsb
	jz  .match
.nomatch:
	xor ax, ax
	jmp .end
.match:
	mov ax,0x01
.end:
	ret
	

%endif
