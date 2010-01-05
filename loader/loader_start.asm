bits 32
global start
extern _ld_main ; this is in the c file

section .text

start:
  call _ld_main
  cli ; stop interrupts
  hlt ; halt the CPU
  
section .data

msg db 'Hello World'