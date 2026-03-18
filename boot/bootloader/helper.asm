print_str:
    mov ah, 0x0e ; tty mode (teletypewriter)
    ; param: si = pointer to null-terminated string
.print_loop:
    lodsb ; load byte at [si] into al and increment si
    cmp al, 0 ; check for null terminator
    je .done
    int 0x10 ; print character in al
    jmp .print_loop
.done:
    ret

printn:
    int 0x10 ; print character in al
    mov al, ':'
    int 0x10
    ret

print_mem:
    call newline

    mov si, mem_dump_msg
    call print_str

    call newline

    mov si, delimiter
    call print_str

    call newline

    mov si, 0x7ff0
    ; mov si, 0x8010

.print_mem_loop:
    lodsb ; load byte at [si] into al and increment si

    cmp si, 0x8010
    je .done

    cmp al, 0
    je .zero_char

    int 0x10 ; print character in al
    mov al, '.'
    int 0x10 ; print '.' for non-zero bytes
    jmp .print_mem_loop
.zero_char:
    mov al, '0'
    int 0x10 ; print '0' for zero bytes
    mov al, '.'
    int 0x10 ; print '.' after '0'
    jmp .print_mem_loop

.done:
    call newline
    mov si, delimiter
    call print_str
    call newline
    
    mov si, mem_dump_done_msg
    call print_str
    call newline

    ret

delimiter:
    db "----------------", 0

mem_dump_msg:
    db "Memory dump:", 0

mem_dump_done_msg:
    db "Memory dump complete. 32 bytes printed.", 0

newline:
    mov al, 0x0a ; newline character
    int 0x10
    mov al, 0x0d ; carriage return character
    int 0x10
    ret