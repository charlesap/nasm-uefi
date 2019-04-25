bits 64
;default rel
org 0x8000000
section .header

DOS:
	dd 0x00005a4d		
	times 14 dd 0
	dd 0x00000080
	times 16 dd 0

PECOFF:
        dd `PE\0\0`		; sig
	dw 0x8664		; type
	dw 3			; sections
	dd 0x5cba52f6		; timestamp
	dq 0			; * symbol table + # symbols
	dw osize 		; oheader size
	dw 0x202e		; characteristics

OHEADER:
	dd 0x0000020b		; oheader + 0000 linker sig
	dd 8192 ;codesize 		; code size
	dd 8192 ;datasize 		; data size
	dd 0			; uninitialized data size
	dd 4096			; * entry
	dd 4096			; * code base
	dq 0x8000000		; * image base
	dd 4096			; section alignment
	dd 4096			; file alignment
	dq 0			; os maj, min, image maj, min
	dq 0			; subsys maj, min, reserved
	dd 28672		; image size
	dd 4096			; headers size
	dd 0			; checksum
	dd 0x0040000A		; dll characteristics & subsystem
	dq 0x10000		; stack reserve size
	dq 0x10000		; stack commit size
	dq 0x10000		; heap reserve size
	dq 0			; heap reserve commit
	dd 0			; loader flags
	dd 0x10			; rva count

DIRS:
	times 5 dq 0		; unused
	dd 0x8005000		; virtual address .reloc
	dd 0			; size .reloc
        times 10 dq 0   	; unused 
OEND:
osize equ OEND - OHEADER

SECTS:
.1:
	dq  `.text`		; name
	dd  8192 ;codesize		; virtual size
	dd  4096		; virtual address	
	dd  8192		; raw data size
	dd  4096		; * raw data
	dq  0			; * relocations, * line numbers
	dd  0			; # relocations, # line numbers
	dd  0x60000020		; characteristics

.2:
        dq  `.data`
        dd  8192 ;datasize		
        dd  12288
        dd  8192 
        dd  12288		
        dq  0
        dd  0
        dd  0xC0000040		


.3:
	dq  `.reloc`
	dd  8192	
	dd  20480
	dd  8192
	dd  20480
	dq  0
	dd  0
	dd  0x02000040

	times 4096 - ($-$$) db 0  ;align the text section on a 4096 byte boundary

section .text follows=.header ; vstart=0x10001000

EFI_SUCCESS                       			equ 0
EFI_SYSTEM_TABLE_SIGNATURE        			equ 0x5453595320494249
EFI_SYSTEM_TABLE_CONOUT               			equ 64
EFI_SYSTEM_TABLE_RUNTIMESERVICES      			equ 88
EFI_SYSTEM_TABLE_BOOTSERVICES         			equ 96

EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_RESET			equ 0
EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OUTPUTSTRING      	equ 8

EFI_BOOT_SERVICES_GETMEMORYMAP				equ 56
EFI_BOOT_SERVICES_LOCATEHANDLE				equ 176
EFI_BOOT_SERVICES_LOADIMAGE				equ 200
EFI_BOOT_SERVICES_EXIT					equ 216
EFI_BOOT_SERVICES_EXITBOOTSERVICES			equ 232
EFI_BOOT_SERVICES_LOCATEPROTOCOL			equ 320

EFI_RUNTIME_SERVICES_RESETSYSTEM			equ 104
EFI_GRAPHICS_OUTPUT_PROTOCOL_MODE			equ 24

EFI_GRAPHICS_OUTPUT_PROTOCOL_MODE_FRAMEBUFFERBASE	equ 32
EFI_GRAPHICS_OUTPUT_PROTOCOL_MODE_FRAMEBUFFERSIZE	equ 40


	sub rsp, 6*8	
	mov [Handle], rcx         
	mov [SystemTable], rdx    

	; find the interface to GOP
	mov rax, [SystemTable]
	mov rax, [rax + EFI_SYSTEM_TABLE_BOOTSERVICES]
	mov rcx, EFI_GRAPHICS_OUTPUT_PROTOCOL_GUID
	mov rdx, 0
	lea r8, [Interface]
	call [rax + EFI_BOOT_SERVICES_LOCATEPROTOCOL]

	mov rcx, [Interface]
	mov rcx, [rcx + EFI_GRAPHICS_OUTPUT_PROTOCOL_MODE]
	mov rbx, [rcx + EFI_GRAPHICS_OUTPUT_PROTOCOL_MODE_FRAMEBUFFERBASE]
	mov [FB], rbx
	mov rcx, [rcx + EFI_GRAPHICS_OUTPUT_PROTOCOL_MODE_FRAMEBUFFERSIZE]
	mov [FBS], rcx
        cmp rax, EFI_SUCCESS
        jne oops
g2:
       lea rdx, [herewego]
       mov rcx, [SystemTable]
       mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]
       call [rcx + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OUTPUTSTRING]

	; get the memory map
	lea rcx, [MMSize]
	lea rdx, [MMap]
	lea r8, [MMKey]
	lea r9, [MMDsz]
	lea r10, [MMDsv]
	push r10
	mov rax, [SystemTable]
	mov rax, [rax + EFI_SYSTEM_TABLE_BOOTSERVICES]
	call [rax + EFI_BOOT_SERVICES_GETMEMORYMAP]
	pop r10
	cmp rax, EFI_SUCCESS
	jne oops
        ; exit boot services
        mov rcx, [Handle]
        mov rdx, [MMKey]
        mov rax, [SystemTable]
        mov rax, [rax + EFI_SYSTEM_TABLE_BOOTSERVICES]
        call [rax + EFI_BOOT_SERVICES_EXITBOOTSERVICES]
        cmp rax, EFI_SUCCESS
        je g5

        ; get the memory map
        lea rcx, [MMSize]
        lea rdx, [MMap]
        lea r8, [MMKey]
        lea r9, [MMDsz]
        lea r10, [MMDsv]
        push r10
        mov rax, [SystemTable]
        mov rax, [rax + EFI_SYSTEM_TABLE_BOOTSERVICES]
        call [rax + EFI_BOOT_SERVICES_GETMEMORYMAP]
        pop r10
        cmp rax, EFI_SUCCESS
        jne oops
        ; exit boot services
        mov rcx, [Handle]
        mov rdx, [MMKey]
        mov rax, [SystemTable]
        mov rax, [rax + EFI_SYSTEM_TABLE_BOOTSERVICES]
        call [rax + EFI_BOOT_SERVICES_EXITBOOTSERVICES]
        cmp rax, EFI_SUCCESS
        jne oops

g5:

       mov rcx, 2 ;EfiResetShutdown    
       mov rdx, EFI_SUCCESS            ; return status
       mov rax, [SystemTable]
       mov rax, [rax + EFI_SYSTEM_TABLE_RUNTIMESERVICES]
       call [rax + EFI_RUNTIME_SERVICES_RESETSYSTEM]

;	add rsp, 6*8
;	mov eax, EFI_SUCCESS 
;	retn
oops:
        lea rdx, [fail]
        mov rcx, [SystemTable]
        mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]
        call [rcx + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OUTPUTSTRING]
	jmp $-1

	times 8192-($-$$) db 0  

codesize equ $ - $$

section .data follows=.text ;vstart=0x10003000    

Handle      dq 0
SystemTable dq 0
Interface   dq 0
FB	    dq 0
FBS	    dq 0
MMSize      dq 4096
MMPtr	    dq 0x8005000
MMKey       dq 0
MMDsz       dq 48
MMDsv       dq 0

EFI_GRAPHICS_OUTPUT_PROTOCOL_GUID db 0xde, 0xa9, 0x42, 0x90, 0xdc, 0x23, 0x38, 0x4a
                                  db 0x96, 0xfb, 0x7a, 0xde, 0xd0, 0x80, 0x51, 0x6a
fail		db __utf16__ `fail.\r\n\0`
nok		db __utf16__ `Not OK.\r\n\0`
yok		db __utf16__ `OK.\r\n\0`
herewego	db __utf16__ `here we go\r\n\0`

	times 4096-($-$$) db 0

MMap:
	times 4096 db 0

datasize equ $ - $$


section .reloc follows=.data ;align=64
xMMap:	times 8192 db 0

