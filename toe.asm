bits 64
org 0x8005000
section .text
global _start
_start:

FB    equ 0x8003000 + 56
FBS   equ 0x8003000 + 64

jmp begin

dw	0
dd	1
dd	2
dd	3
dd	4
dd	5
dd	6
dd	7

begin:
mov r8, 0x1111BBBB66660000
mov rcx, [FB]
mov rax, [FBS]
Q:
sub rax, 8
mov [rcx+rax],r8
jnz Q

jmp $


