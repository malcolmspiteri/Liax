%ifndef _RS_INC
%define _RS_INC

%define COM1 0x3F8
%define COM1IOP(a) COM1 + a
	
test:
	xor al,0x0
	mov dx,WORD COM1IOP(1)
	out dx,al	; Turn off interrupts - Port1
	
	mov al, 0x80
	mov dx,WORD COM1IOP(3)
	out dx,al	; SET DLAB ON
	
	mov al, 0x0c
	mov dx,WORD COM1IOP(0)
	out dx,al	; Set Baud rate - Divisor Latch Low Byte
	
	mov al, 0x0
	mov dx,WORD COM1IOP(1)
	out dx,al	; Set Baud rate - Divisor Latch High Byte
	
	mov al, 0x03
	mov dx,WORD COM1IOP(3)
	out dx,al	; 8 Bits, No Parity, 1 Stop Bit
	
	mov al, 0xc7
	mov dx,WORD COM1IOP(2)
	out dx,al	; FIFO Control Register
	
	mov al, 0x0b
	mov dx,WORD COM1IOP(4)
	out dx,al	; Turn on DTR, RTS, and OUT2

	;; Set Programmable Interrupt Controller - Unmask IRQ 4
	in al, 0x21
	and al, 0xef
	out 0x21,al

	;; Re-enable interrupts
	mov al, 0x01
	mov dx,WORD COM1IOP(1)	
	out dx,al	

	xor al,al
	mov al,0x35
	mov dx, WORD COM1IOP(0)
	out dx,al
	out dx,al
	out dx,al
	out dx,al
	out dx,al
	out dx,al
	ret	

%endif