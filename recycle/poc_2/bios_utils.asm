; Source name     : boot_utils.asm
; Executable name : boot_utils.bin
; Code model:     : Real mode flat model
; Version         : 1.0
; Created date    : 28/11/2009
; Last update     : 28/11/2009
; Author          : Malcolm Spiteri
; Description     : Various utilities invoking BIOS services

println:

	call print
	mov al,0x000D
    int 0x10
	mov al,0x000A
    int 0x10

.done:
    retn
	
print:

    lodsb           						; AL = [DS:SI]
    or al,al        						; Set zero flag if al=0
    jz .done 								; Jump to .done if zero flag is set
    mov ah,0x0E								; Video function 0Eh
    mov bx,0x0007							; Color
    int 0x10
    jmp print								; Load characters until AL=0
	
.done:
    retn
