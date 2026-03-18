[org 0x7C00] ; Origin address for the bootloader

mov ah, 0x0e ; tty mode (teletypewriter)
mov si, hello_string
call print_str

mov al, ' '
int 0x10


;;; some testing
mov bp, 0x8000
mov sp, bp

push 'A'
push 'B'
push 'C'

call print_mem

mov al, '1'
call printn

; pop bx
mov al, [0x7ffc] ; this is B for some reasons
int 0x10

mov al, '2'
call printn

mov al, [0x7ffe] ; read from memory address 0x7FFE, which should be 'A'
int 0x10
;;;

jmp $ ; jump to current address = infinite loop

%include "helper.asm"

hello_string:
    db "Hello!", 0

the_secret:
    db "X"

; Boostrap code
; Fill with 446 zeros minus the size of the previous code
times 446-($-$$) db 0
; Address: 0x1BE

; Partition table (64 bytes)
times 16 db 0 ; Disk signature and unused
times 48 db 0 ; Partition entries 2-4 (4 entries of 16 bytes each)
; Address: 0x1BE + 64 = 0x1FE

; Magic number MBR signature
dw 0xAA55
; Address: 0x1FE + 2 = 0x200