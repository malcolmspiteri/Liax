bits 16
org 0x0

section .text

%include "video_utils.asm"

start:
	mov si, msg
	call write
	
section .data

msg db 'Hello party poeple', 0x0
CRLF 			db 0x0D, 0x0A, 0x0