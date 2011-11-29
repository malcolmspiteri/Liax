%ifndef _BIOS_INC
%define _BIOS_INC

;; BIOS Video Modes
%define MODE_640x350_16_COLOR_GRAPHICS 0x10
	
;; BIOS Colors
%define COLOR_BLACK 0x00 	
%define COLOR_BLUE 0x01 	
%define COLOR_GREEN 0x02 	
%define COLOR_CYAN 0x03 	
%define COLOR_RED 0x04 	
%define COLOR_MAGENTA 0x05 	
%define COLOR_BROWN 0x06 	
%define COLOR_LIGHT_GRAY 0x07 	
%define COLOR_DARK_GRAY 0x08 	
%define COLOR_LIGHT_BLUE 0x09 	
%define COLOR_LIGHT_GREEN 0x0A 	
%define COLOR_LIGHT_CYAN 0x0B 	
%define COLOR_LIGHT_RED 0x0C 	
%define COLOR_LIGHT_MAGENTA 0x0D 	
%define COLOR_YELLOW 0x0E 	
%define COLOR_WHITE 0x0F

%define BIOS_COLOR(b,f) (b<<4)|f
%define DEFAULT_COLOR_SCHEME BIOS_COLOR(COLOR_BLACK, COLOR_LIGHT_GRAY)
	
;; BIOS Interrupts
%define INT_VIDEO_SERVICES 0x10
%define INT_DISK_SERVICES 0x13

;; BIOS Functions
%define RESET_DISK_SYSTEM 0x00

%define SET_VIDEO_MODE 0x00
%define SET_CURSOR_POSITION 0x02
%define SCROLL_UP_WINDOW 0x06
%define WRITE_CHAR_TTY 0x0E

%define READ_DISK_SECTORS 0x02

%macro BIOS_SCROLL_UP_WINDOW 6
	mov ah,SCROLL_UP_WINDOW	; scroll up function id. 
	mov al,%1	; no of lines to scroll
	mov bh,%2	; attribute to be used on blank line
	mov ch,%3	; upper row. 
	mov cl,%4	; upper col. 
	mov dh,%5 	; lower row (byte). 
	mov dl,%6	; lower col. 
	int INT_VIDEO_SERVICES
%endmacro

%macro BIOS_SET_CURSOR_POSITION 0-3 0,0,0
	mov bh, %1	; page. 
	mov dh, %2	; row. 
	mov dl, %3	; col. 
	mov ah, SET_CURSOR_POSITION	; BIOS function
	int INT_VIDEO_SERVICES
%endmacro

%macro BIOS_SET_VIDEO_MODE 1
	mov ah,SET_VIDEO_MODE
	mov al,%1
	int INT_VIDEO_SERVICES
%endmacro
	
%macro BIOS_WRITE_CHAR_TTY 1
	mov ah,WRITE_CHAR_TTY	; Set funtion
	mov bh,0x0		; Page 0
	mov bl,%1
	int INT_VIDEO_SERVICES
%endmacro

;; BIOS disk services

%define READ_DISK_SECTORS_RETRIES 0x03
	
struc dchs
      drive:		resb	1
      cylinder:		resb	1
      head:		resb	1
      sector:		resb 	1
endstruc

%macro BIOS_RESET_DISK_SYSTEM 1
	mov ah, RESET_DISK_SYSTEM
	mov dl, %1
	int INT_DISK_SERVICES	
%endmacro
	
%macro BIOS_READ_SECTORS 5
	mov di, 0x0
%%retry:
	cmp di, READ_DISK_SECTORS_RETRIES
	jz %5
	BIOS_RESET_DISK_SYSTEM BYTE[%4+drive]
	inc di
	xor ax, ax
	xor bx, bx
	mov ax, %1
	mov es, ax
	mov bx, %2
	mov ah, READ_DISK_SECTORS
	mov al, %3			; no of sectors
	mov dl, BYTE[%4+drive]		; drive
	mov ch, BYTE[%4+cylinder]	; cylinder
	mov dh, BYTE[%4+head]		; head
	mov cl, BYTE[%4+sector]		; sector
	int INT_DISK_SERVICES
	jc %%retry
	
%endmacro

%endif
