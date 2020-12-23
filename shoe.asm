bits 64
org 0x8000000
section .header

DOS:
    dd 0x00005a4d
    times 14 dd 0
    dd 0x00000080
    times 16 dd 0

PECOFF:
        dd `PE\0\0`     ; sig
    dw 0x8664       ; type
    dw 3            ; sections
    dd 0x5cba52f6       ; timestamp
    dq 0            ; * symbol table + # symbols
    dw osize        ; oheader size
    dw 0x202e       ; characteristics

OHEADER:
    dd 0x0000020b       ; oheader + 0000 linker sig
    dd 8192 ;codesize       ; code size
    dd 270336 ;was 8192 ;datasize       ; data size
    dd 0            ; uninitialized data size
    dd 4096         ; * entry
    dd 4096         ; * code base
    dq 0x8000000        ; * image base 
    dd 4096         ; section alignment
    dd 4096         ; file alignment
    dq 0            ; os maj, min, image maj, min
    dq 0            ; subsys maj, min, reserved
    dd 282624 ; was  0x5000        image size
    dd 4096         ; headers size
    dd 0            ; checksum
    dd 0x0040000A       ; dll characteristics & subsystem
    dq 0x10000      ; stack reserve size
    dq 0x10000      ; stack commit size
    dq 0x10000      ; heap reserve size
    dq 0            ; heap reserve commit
    dd 0            ; loader flags
    dd 0x10         ; rva count

DIRS:
    times 5 dq 0        ; unused
    dd 0x8005000        ; virtual address .reloc
    dd 0            ; size .reloc
        times 10 dq 0       ; unused
OEND:
osize equ OEND - OHEADER

SECTS:
.1:
    dq  `.text`     ; name
    dd  8192 ;codesize      ; virtual size
    dd  4096        ; virtual address
    dd  8192        ; raw data size
    dd  4096        ; * raw data
    dq  0           ; * relocations, * line numbers
    dd  0           ; # relocations, # line numbers
    dd  0x60000020      ; characteristics

.2:
        dq  `.data`
        dd  270336 ; was 8192 datasize
        dd  12288
        dd  270336 ; was 8192
        dd  12288
        dq  0
        dd  0
        dd  0xC0000040


.3:
    dq  `.reloc`
    dd  0
    dd  282624; was 20480
    dd  0
    dd  282624; was 20480
    dq  0
    dd  0
    dd  0x02000040

    times 4096 - ($-$$) db 0  ;align the text section on a 4096 byte boundary

section .text follows=.header

EFI_SUCCESS                                 equ 0
EFI_SYSTEM_TABLE_SIGNATURE                  equ 0x5453595320494249
EFI_SYSTEM_TABLE_CONOUT                         equ 64
EFI_SYSTEM_TABLE_RUNTIMESERVICES                equ 88
EFI_SYSTEM_TABLE_BOOTSERVICES                   equ 96

EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_RESET           equ 0
EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OUTPUTSTRING        equ 8

EFI_BOOT_SERVICES_GETMEMORYMAP              equ 56
EFI_BOOT_SERVICES_LOCATEHANDLE              equ 176
EFI_BOOT_SERVICES_LOADIMAGE             equ 200
EFI_BOOT_SERVICES_EXIT                  equ 216
EFI_BOOT_SERVICES_EXITBOOTSERVICES          equ 232
EFI_BOOT_SERVICES_LOCATEPROTOCOL            equ 320

EFI_RUNTIME_SERVICES_RESETSYSTEM            equ 104


sub rsp, 6*8+8    ; Stack is misaligned by 8 when control is transferred to
                   ; the EFI entry point. In addition to the shadow space
                   ; (32 bytes) and space for stack based paramaters to be
                   ; saved - we also have to allocate an additional
                   ; 8 bytes to ensure stack alignment on a 16-byte boundary
                   ; 8+(6*8+8)=64, 64 is evenly divisible by 16 at this point

mov [Handle], rcx
mov [SystemTable], rdx

mov rax, [SystemTable]
mov rax, [rax + EFI_SYSTEM_TABLE_BOOTSERVICES]
mov [BS], rax

mov rax, [SystemTable]
mov rax, [rax + EFI_SYSTEM_TABLE_RUNTIMESERVICES]
mov [RTS], rax

lea rdx, [herewego]
mov rcx, [SystemTable]
mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]
call [rcx + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OUTPUTSTRING]

; get the memory map
mov qword [memmapsize], 4096
lea rcx, [memmapsize]
lea rdx, [memmap]
lea r8, [memmapkey]
lea r9, [memmapdescsize]
lea r10, [memmapdescver]
mov [rsp+32], r10         ; Don't push R10 on the stack, move it directly to
                           ; the stack immediately above the shadow space
mov rbx, [BS]
call [rbx + EFI_BOOT_SERVICES_GETMEMORYMAP]
cmp rax, EFI_SUCCESS
jne oops

; find the interface to GOP
mov rbx, [SystemTable]
mov rbx, [rbx + EFI_SYSTEM_TABLE_BOOTSERVICES]
mov rcx, _EFI_GRAPHICS_OUTPUT_PROTOCOL_GUID
mov rdx, 0
lea r8, [Interface]
call [rbx + EFI_BOOT_SERVICES_LOCATEPROTOCOL]
cmp rax, EFI_SUCCESS
jne oops

;	horizontalResolution = gop->Mode->Info->HorizontalResolution;
;	verticalResolution = gop->Mode->Info->VerticalResolution;

; 0  UINT32 	Version The version of this data structure. More...
; 4  UINT32 	HorizontalResolution The size of video screen in pixels in the X dimension. 
; 8  UINT32 	VerticalResolution The size of video screen in pixels in the Y dimension. 
; 12 (enum) EFI_GRAPHICS_PIXEL_FORMAT 0-RGBX 1-BGRX 2-PixelBitMask 3-PixelBLTOnly 4-PixelFormatMax PixelFormat Enumeration that defines the physical format of the pixel. 
; 16 EFI_PIXEL_BITMASK 	PixelInformation This bit-mask is only valid if PixelFormat is set to PixelPixelBitMask. 
; 32 UINT32 	PixelsPerScanLine Defines the number of pixel elements per video memory line. 
 
;typedef struct {
;   UINT32            RedMask;
;   UINT32            GreenMask;
;   UINT32            BlueMask;
;   UINT32            ReservedMask;
; } EFI_PIXEL_BITMASK;


mov rcx, [Interface]
mov rcx, [rcx + 0x18 ] ;EFI_GRAPHICS_OUTPUT_PROTOCOL_MODE
mov rbx, [rcx + 0x18 ] ;EFI_GRAPHICS_OUTPUT_PROTOCOL_MODE_FRAMEBUFFERBASE
mov [FB], rbx
mov rcx, [rcx + 0x20 ] ;EFI_GRAPHICS_OUTPUT_PROTOCOL_MODE_FRAMEBUFFERSIZE
mov [FBS], rcx
cmp rax, EFI_SUCCESS
jne oops

       mov rbx, [FB]
       call printhex

       mov rbx, [FBS]
       call printhex

; exit boot services
mov rcx, [Handle]
mov rdx, [memmapkey]
mov rbx, [SystemTable]
mov rbx, [rbx + EFI_SYSTEM_TABLE_BOOTSERVICES]
call [rbx + EFI_BOOT_SERVICES_EXITBOOTSERVICES]
cmp rax, EFI_SUCCESS
; je g5
je fillframe

       mov rbx, [memmapkey]
       call printhex

; repeat the call to get the memory map
mov qword [memmapsize], 4096
lea rcx, [memmapsize]
lea rdx, [memmap]
lea r8, [memmapkey]
lea r9, [memmapdescsize]
lea r10, [memmapdescver]
mov rbx, [BS]
mov [rsp+32], r10         ; Don't push R10 on the stack, move it directly to
                           ; the stack immediately above the shadow space
call [rbx + EFI_BOOT_SERVICES_GETMEMORYMAP]
cmp rax, EFI_SUCCESS
jne oops

       mov rbx, [memmapkey]
       call printhex

; exit boot services again
mov rcx, [Handle]
mov rdx, [memmapkey]
xor r8, r8
mov rbx, [SystemTable]
mov rbx, [rbx + EFI_SYSTEM_TABLE_BOOTSERVICES]
call [rbx + EFI_BOOT_SERVICES_EXITBOOTSERVICES]
;cmp rax, EFI_SUCCESS
;je g5
;jmp oops

fillframe:
mov rcx, [FB]
mov rax, [FBS]
Q:
dec rax
mov byte[rcx+rax],255
jnz Q

W:
jmp W

g5:
mov rcx, 2 ;EfiResetShutdown
mov rdx, EFI_SUCCESS
mov rax, [SystemTable]
mov rax, [rax + EFI_SYSTEM_TABLE_RUNTIMESERVICES]
call [rax + EFI_RUNTIME_SERVICES_RESETSYSTEM]

oops:
lea rdx, [fail]
mov rcx, [SystemTable]
mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]
call [rcx + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OUTPUTSTRING]
jmp $

printhex:
                         ; Stack msialigned by 8 at function entry
mov rbp, 16
push rax
push rcx
push rdx                ; 3 pushes also align stack on 16 byte boundary
                         ; (8+3*8)=32, 32 evenly divisible by 16
sub rsp, 32             ; Allocate 32 bytes of shadow space
.loop:
    rol rbx, 4
    mov rax, rbx
    and rax, 0Fh
    lea rcx, [_Hex]
    mov rax, [rax + rcx]
    mov byte [_Num], al
        lea rdx, [_Num]
        mov rcx, [SystemTable]
        mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]
        call [rcx + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OUTPUTSTRING]
    dec rbp
jnz .loop
lea rdx, [_Nl]
mov rcx, [SystemTable]
mov rcx, [rcx + EFI_SYSTEM_TABLE_CONOUT]
call [rcx + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_OUTPUTSTRING]

add rsp, 32
pop rdx
pop rcx
pop rax
ret

    times 8192-($-$$) db 0

codesize equ $ - $$

section .data follows=.text

Handle          dq 0
SystemTable     dq 0
Interface       dq 0
BS      dq 0
RTS     dq 0
STK         dq 0
FB              dq 0
FBS             dq 0
memmapsize      dq 4096
memmapkey       dq 0
memmapdescsize  dq 48
memmapdescver   dq 0

_EFI_GRAPHICS_OUTPUT_PROTOCOL_GUID db 0xde, 0xa9, 0x42, 0x90, 0xdc, 0x23, 0x38, 0x4a
                                  db 0x96, 0xfb, 0x7a, 0xde, 0xd0, 0x80, 0x51, 0x6a
fail     db __utf16__ `fail.\r\n\0`
nok      db __utf16__ `Not OK.\r\n\0`
yok      db __utf16__ `OK.\r\n\0`
herewego db __utf16__ `here we go\r\n\0`
_Hex     db '0123456789ABCDEF'
_Num     dw 0,0
_Nl      dw 13,10,0

    times 4096-($-$$) db 0

memmap:
    times 4096 db 0
payload:     ;64 4k pages=262144 (256k)
    times 262144 db 0
datasize equ $ - $$


section .reloc follows=.data
