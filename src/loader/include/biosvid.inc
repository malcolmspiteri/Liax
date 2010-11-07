%ifndef _BIOSVID_INC
%define _BIOSVID_INC

;; *********************************************************
;; Use BIOS service 10/E to write on the screen in tty mode
;; *********************************************************
write:	
%ifndef STGONE
.init:
	GET_PARAM 1
	mov si,ax	; Get the pointer to the start of the text
%endif
.start:
	lodsb          	; AL = [DS:SI]
	or al,al      	; Set zero flag if al=0
	jz .end 	; Jump to .end if zero flag is set
	mov ah,0x0E	; Video function 0Eh
	mov bx,0x0007	; Color
	int 0x10
	jmp .start	; Load characters until AL=0	
.end:
	ret

%ifndef STGONE

set_cursor:
	GET_PARAM 1
	mov bh, al			; page. 
	GET_PARAM 2
	mov dh, al			; row. 
	GET_PARAM 3
	mov dl, al			; col. 
	mov ah,0x02			; BIOS function
	int 0x10
	ret

clear_screen:

	; Clear the screen using BIOS video service
	mov ax,0x0040
	mov fs,ax  		; for getting screen parameters. 
	mov ah,0x06 		; scroll up function id. 
	mov al,0x0   		; scroll all lines! 
	mov bh,0x07  		; attribute for new lines. 
	mov ch,0x0   		; upper row. 
	mov cl,0x0   		; upper col. 
	mov di,0x0084 		; rows on screen -1, 
	mov dh,BYTE [fs:di] 	; lower row (byte). 
	mov di,0x004A 		; columns on screen, 
	mov dl,BYTE [fs:di]
	dec dl				; lower col. 
	int 0x10
	ret
	
%endif

%endif