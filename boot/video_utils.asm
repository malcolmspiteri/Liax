;clear_screen:
;	push ax       	; Push registers on the stack
;	push bx
;	push cx
;	push dx
;	push ds
;	push di
;	; Clear the screen using BIOS video service
;	mov ax,0x0040
;	mov ds,ax  			; for getting screen parameters. 
;	mov ah,0x06 		; scroll up function id. 
;	mov al,0x0   		; scroll all lines! 
;	mov bh,0x07  		; attribute for new lines. 
;	mov ch,0x0   		; upper row. 
;	mov cl,0x0   		; upper col. 
;	mov di,0x0084 		; rows on screen -1, 
;	mov dh,[di] 		; lower row (byte). 
;	mov di,0x004A 		; columns on screen, 
;	mov dl,[di]
;	dec dl				; lower col. 
;	int 0x10
;	; set cursor position to top 
;	; of the screen: 
;	mov bh,0x0   		; current page. 
;	mov dl,0x0   		; col. 
;	mov dh,0x01   		; row. 
;	mov ah,0x02
;	int 0x10
;	; re-store registers... 
;	pop di      
;	pop ds       
;	pop dx      
;	pop cx      
;	pop bx       
;	pop ax       
;	; return
;	ret
	
write:	
.start:
    lodsb           				; AL = [DS:SI]
    or al,al        				; Set zero flag if al=0
    jz .success 					; Jump to .success if zero flag is set
    mov ah,0x0E						; Video function 0Eh
    mov bx,0x0007					; Color
    int 0x10
    jmp .start						; Load characters until AL=0	
.success:
	ret

write_line:
	call write
	mov si, CRLF
    call write
	ret