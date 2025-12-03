; ----------------------------------------------------------------------------------------
; Program to display CPUID (EAX=1) Full Info
; Source: Intel SDM Vol 2A - CPUID instruction
; ----------------------------------------------------------------------------------------

section .data
    msg_title   db "--- CPUID (EAX=1) Full Info ---", 0xA, 0
    len_title   equ $-msg_title

    ; Messages related to raw values
    msg_eax     db "Raw EAX: 0x", 0
    msg_ebx     db "Raw EBX: 0x", 0
    msg_ecx     db "Raw ECX: 0x", 0
    msg_edx     db "Raw EDX: 0x", 0
    
    ; Messages related to Processor Info (EAX)
    msg_fam     db 0xA, "--- Processor Info (EAX) ---", 0xA, "  > Family:   ", 0
    msg_mod     db "  > Model:    ", 0
    msg_step    db "  > Stepping: ", 0

    ; New messages related to EBX details
    msg_ebx_det db 0xA, "--- Additional Info (EBX) ---", 0xA, 0
    msg_brand   db "  > Brand Index:    ", 0
    msg_chunks  db "  > CLFLUSH Chunks: ", 0
    msg_count   db "  > Log. CPU Count: ", 0
    msg_apic    db "  > Init. APIC ID:  ", 0

    newline     db 0xA

section .bss
    HexBuf      resb 8      ; Hex buffer
    DecBuf      resb 10     ; Decimal buffer
    
    ; Raw variables
    RawEAX      resd 1      
    RawEBX      resd 1
    RawECX      resd 1
    RawEDX      resd 1

    ; Calculated variables
    BaseFamily  resd 1
    BaseModel   resd 1
    FinalFamily resd 1
    FinalModel  resd 1

section .text
    global _start

_start:
    ; --- Print main title ---
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_title
    mov edx, len_title
    int 0x80

    ; --- 1. Execute CPUID ---
    mov eax, 1
    cpuid
    
    ; --- Save outputs ---
    mov [RawEAX], eax
    mov [RawEBX], ebx
    mov [RawECX], ecx
    mov [RawEDX], edx

    ; =========================================================
    ; Print raw values (Raw Hex Dump)
    ; =========================================================

    ; Print EAX
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_eax
    mov edx, 11
    int 0x80
    mov eax, [RawEAX]
    call print_hex
    call print_newline

    ; Print EBX
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_ebx
    mov edx, 11
    int 0x80
    mov eax, [RawEBX]
    call print_hex
    call print_newline

    ; Print ECX
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_ecx
    mov edx, 11
    int 0x80
    mov eax, [RawECX]
    call print_hex
    call print_newline

    ; Print EDX
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_edx
    mov edx, 11
    int 0x80
    mov eax, [RawEDX]
    call print_hex
    call print_newline

    ; =========================================================
    ; Calculate and print EAX info (Family/Model)
    ; =========================================================
    
    ; Calculations (Same logic as before)
    mov eax, [RawEAX]
    shr eax, 4
    and eax, 0x0F
    mov [BaseModel], eax

    mov eax, [RawEAX]
    shr eax, 8
    and eax, 0x0F
    mov [BaseFamily], eax

    mov eax, [BaseFamily]
    mov ebx, eax
    cmp eax, 15
    jne .store_family
    mov eax, [RawEAX]
    shr eax, 20
    and eax, 0xFF
    add ebx, eax
.store_family:
    mov [FinalFamily], ebx

    mov eax, [BaseFamily]
    mov ebx, [BaseModel]
    cmp eax, 6
    je .calc_extended_model
    cmp eax, 15
    je .calc_extended_model
    jmp .store_model
.calc_extended_model:
    mov eax, [RawEAX]
    shr eax, 16
    and eax, 0x0F
    shl eax, 4
    add ebx, eax
.store_model:
    mov [FinalModel], ebx

    ; --- Print EAX Info ---
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_fam    ; Section title + Family
    mov edx, 45         ; Approximate length of combined string
    int 0x80
    
    mov eax, [FinalFamily]
    call print_decimal
    call print_newline

    mov eax, 4
    mov ebx, 1
    mov ecx, msg_mod
    mov edx, 14
    int 0x80
    
    mov eax, [FinalModel]
    call print_decimal
    call print_newline

    mov eax, 4
    mov ebx, 1
    mov ecx, msg_step
    mov edx, 14
    int 0x80
    
    mov eax, [RawEAX]
    and eax, 0x0F
    call print_decimal
    call print_newline

    ; =========================================================
    ; New Section: Extract and print EBX details
    ; =========================================================

    ; EBX Section Title
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_ebx_det
    mov edx, 31         ; Title string length
    int 0x80

    ; 1. Brand Index (Bits 0-7)
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_brand
    mov edx, 20
    int 0x80

    mov eax, [RawEBX]
    and eax, 0xFF       ; Only lower 8 bits
    call print_decimal
    call print_newline

    ; 2. CLFLUSH Line Size (Bits 8-15)
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_chunks
    mov edx, 20
    int 0x80

    mov eax, [RawEBX]
    shr eax, 8          ; Shift right by 8 bits
    and eax, 0xFF       ; Masking
    call print_decimal
    call print_newline

    ; 3. Logical Processor Count (Bits 16-23)
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_count
    mov edx, 20
    int 0x80

    mov eax, [RawEBX]
    shr eax, 16         ; Shift right by 16 bits
    and eax, 0xFF
    call print_decimal
    call print_newline

    ; 4. Initial APIC ID (Bits 24-31)
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_apic
    mov edx, 20
    int 0x80

    mov eax, [RawEBX]
    shr eax, 24         ; Shift right by 24 bits
    and eax, 0xFF
    call print_decimal
    call print_newline

    ; Exit
    mov eax, 1
    xor ebx, ebx
    int 0x80

; ---------------------------------------------------------
; Helper subroutines (Unchanged)
; ---------------------------------------------------------
print_newline:
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80
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
    rets