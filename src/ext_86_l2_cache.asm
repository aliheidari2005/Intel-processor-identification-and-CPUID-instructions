; ----------------------------------------------------------------------------------------
; Program to display Extended L2 Cache Info (CPUID EAX=80000006h)
; Includes display of raw ECX value
; ----------------------------------------------------------------------------------------

section .data
    msg_title   db "--- CPUID (EAX=80000006h) Extended L2 Cache ---", 0xA, 0
    len_title   equ $-msg_title

    msg_check   db "Checking support...", 0xA, 0
    
    ; New message for raw value
    msg_raw     db "Raw ECX Value: 0x", 0

    msg_size    db 0xA, "L2 Cache Size:      ", 0
    msg_line    db "L2 Cache Line Size: ", 0
    msg_assoc   db "L2 Associativity:   ", 0
    
    str_disabled db "Disabled", 0xA, 0
    str_direct   db "Direct Mapped", 0xA, 0
    str_2way     db "2-Way", 0xA, 0
    str_4way     db "4-Way", 0xA, 0
    str_8way     db "8-Way", 0xA, 0
    str_16way    db "16-Way", 0xA, 0
    str_full     db "Fully Associative", 0xA, 0
    str_other    db "Other / Reserved", 0xA, 0

    msg_kb      db " KB", 0xA, 0
    msg_byte    db " Bytes", 0xA, 0
    msg_no_sup  db "Function 80000006h not supported.", 0xA, 0

    newline     db 0xA

section .bss
    HexBuf      resb 8
    DecBuf      resb 10
    RawECX      resd 1

section .text
    global _start

_start:
    ; Print title
    mov ecx, msg_title
    mov edx, len_title
    call print_string

    ; --- 1. Check Support ---
    mov ecx, msg_check
    mov edx, 20
    call print_string

    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000006
    jb .not_supported

    ; --- 2. Execute CPUID ---
    mov eax, 0x80000006
    cpuid
    mov [RawECX], ecx   ; All data is in ECX

    ; --- New Section: Print Raw ECX Value ---
    mov ecx, msg_raw
    mov edx, 15
    call print_string
    
    mov eax, [RawECX]
    call print_hex      ; Print hexadecimal value
    call print_newline

    ; =========================================================
    ; 3. Extract Cache Size
    ; Bits 31:16
    ; =========================================================
    mov ecx, msg_size
    mov edx, 21         ; Length slightly longer due to newline at start
    call print_string
    
    mov eax, [RawECX]
    shr eax, 16         ; Shift top 16 bits to bottom
    call print_decimal
    
    mov ecx, msg_kb
    mov edx, 4
    call print_string

    ; =========================================================
    ; 4. Extract Associativity
    ; Bits 15:12
    ; =========================================================
    mov ecx, msg_assoc
    mov edx, 20
    call print_string
    
    mov eax, [RawECX]
    shr eax, 12
    and eax, 0x0F       ; Mask 4 bits
    
    ; Save Hex code for more precise debugging if needed
    push eax
    call print_assoc_type
    pop eax

    ; =========================================================
    ; 5. Extract Line Size
    ; Bits 7:0
    ; =========================================================
    mov ecx, msg_line
    mov edx, 20
    call print_string
    
    mov eax, [RawECX]
    and eax, 0xFF       ; Lower 8 bits
    call print_decimal
    
    mov ecx, msg_byte
    mov edx, 7
    call print_string
    
    jmp .exit

.not_supported:
    mov ecx, msg_no_sup
    mov edx, 34
    call print_string

.exit:
    mov eax, 1
    xor ebx, ebx
    int 0x80

; =========================================================
; Subroutines
; =========================================================

print_assoc_type:
    cmp eax, 0x00
    je .p_dis
    cmp eax, 0x01
    je .p_dir
    cmp eax, 0x02
    je .p_2w
    cmp eax, 0x04
    je .p_4w
    cmp eax, 0x06
    je .p_8w
    cmp eax, 0x08
    je .p_16w
    cmp eax, 0x0F
    je .p_full
    
    ; Default
    mov ecx, str_other
    mov edx, 17
    jmp .do_print

.p_dis:
    mov ecx, str_disabled
    mov edx, 9
    jmp .do_print
.p_dir:
    mov ecx, str_direct
    mov edx, 14
    jmp .do_print
.p_2w:
    mov ecx, str_2way
    mov edx, 6
    jmp .do_print
.p_4w:
    mov ecx, str_4way
    mov edx, 6
    jmp .do_print
.p_8w:
    mov ecx, str_8way
    mov edx, 6
    jmp .do_print
.p_16w:
    mov ecx, str_16way
    mov edx, 7
    jmp .do_print
.p_full:
    mov ecx, str_full
    mov edx, 18

.do_print:
    mov eax, 4
    mov ebx, 1
    int 0x80
    ret

; --- Standard Functions ---
print_string:
    push eax
    push ebx
    mov eax, 4
    mov ebx, 1
    int 0x80
    pop ebx
    pop eax
    ret

print_newline:
    push eax
    push ebx
    push ecx
    push edx
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

print_hex:
    pushad
    mov ecx, 8
    mov edi, HexBuf
.hex_loop:
    rol eax, 4
    mov bl, al
    and bl, 0x0F
    cmp bl, 9
    ja .hex_letter
    add bl, '0'
    jmp .hex_store
.hex_letter:
    add bl, 'A' - 10
.hex_store:
    mov [edi], bl
    inc edi
    dec ecx
    jnz .hex_loop
    mov eax, 4
    mov ebx, 1
    mov ecx, HexBuf
    mov edx, 8
    int 0x80
    popad
    ret

print_decimal:
    pushad
    mov ecx, 0
    mov ebx, 10
.div_loop:
    xor edx, edx
    div ebx
    push edx
    inc ecx
    test eax, eax
    jnz .div_loop
    mov edi, DecBuf
.print_loop:
    pop eax
    add al, '0'
    mov [edi], al
    push ecx
    mov eax, 4
    mov ebx, 1
    mov ecx, edi
    mov edx, 1
    int 0x80
    pop ecx
    dec ecx
    jnz .print_loop
    popad
    ret