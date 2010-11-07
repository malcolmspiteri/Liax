%ifndef _BIOSMEM_INC
%define _BIOSMEM_INC

;; Use the BIOS service 0x12 to acquire the amount of low memory on the system

get_lomem:
	
	GET_PARAM 1, bx		; Memory address where to write return value
	GET_PARAM 2, dx		; Memory address to jump to in case of failure
	xor ax, ax
	int 0x12			; request low memory size
	jc .error
	or ax, ax			; size = 0 is an error
	je .error
	cmp ah, 0x86		; unsupported function
	je .error
	cmp ah, 0x80		; invalid command
	jne .end
.error:
	jmp dx
.end:
	mov WORD [bx], ax
	ret

%endif
