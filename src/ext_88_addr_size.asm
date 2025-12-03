; ----------------------------------------------------------------------------------------
; Program to display Physical and Virtual Address Sizes (CPUID EAX=80000008h)
; Source: Application Note 485 - Table 5-27
; ----------------------------------------------------------------------------------------

section .data
    msg_title   db "--- CPUID (EAX=80000008h) Address Sizes ---", 0xA, 0
    len_title   equ $-msg_title

    msg_check   db "Checking support...", 0xA, 0
    
    msg_phys    db "Physical Address Bits: ", 0
    msg_virt    db "Virtual  Address Bits: ", 0
    
    msg_no_sup  db "Function 80000008h not supported.", 0xA, 0

    newline     db 0xA

section .bss
    DecBuf      resb 10
    RawEAX      resd 1

section .text
    global _start

_start:
    ; Print title
    mov ecx, msg_title
    mov edx, len_title
    call print_string

    ; --- 1. Check support ---
    mov ecx, msg_check
    mov edx, 20
    call print_string

    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000008
    jb .not_supported

    ; --- 2. Execute CPUID ---
    mov eax, 0x80000008
    cpuid
    mov [RawEAX], eax   ; All important data is in EAX

    ; =========================================================
    ; 3. Extract Physical Address Bits
    ; Bits 7:0 (EAX & 0xFF)
    ; =========================================================
    mov ecx, msg_phys
    mov edx, 23
    call print_string
    
    mov eax, [RawEAX]
    and eax, 0xFF       ; Only lower 8 bits
    call print_decimal
    call print_newline

    ; =========================================================
    ; 4. Extract Virtual Address Bits
    ; Bits 15:8 ((EAX >> 8) & 0xFF)
    ; =========================================================
    mov ecx, msg_virt
    mov edx, 23
    call print_string
    
    mov eax, [RawEAX]
    shr eax, 8          ; Shift second byte to bottom
    and eax, 0xFF       ; Masking
    call print_decimal
    call print_newline
    
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