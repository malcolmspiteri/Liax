%define INIT_SEG 0x7c00

; 2.ASM
    ; Print "Hello Cyberspace!" on the screen and hang

    ; Tell the compiler that this is offset 0.
    ; It isn't offset 0, but it will be after the jump.
    [ORG 0]

            jmp 07C0h:start     ; Goto segment 07C0

    ; Declare the string that will be printed
    msg     db  'Hello Cyberspace!'


    start:
            ; Update the segment registers
            mov ax, cs
            mov ds, ax
            mov es, ax


            mov si, msg     ; Print msg
    print:
            lodsb           ; AL=memory contents at DS:SI

            cmp al, 0       ; If AL=0 then hang
            je hang

            mov ah, 0Eh     ; Print AL
            mov bx, 7
            int 10h

            jmp print       ; Print next character


    hang:                   ; Hang!
            jmp hang


    times 510-($-$$) db 0
    dw 0AA55h