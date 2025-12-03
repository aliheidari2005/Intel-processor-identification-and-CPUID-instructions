; ----------------------------------------------------------------------------------------
; Program to display Advanced Power Management Info (CPUID EAX=80000007h)
; Check Invariant TSC capability
; Source: Application Note 485 - Section 5.2.6 & Table 5-26
; ----------------------------------------------------------------------------------------

section .data
    msg_title   db "--- CPUID (EAX=80000007h) Advanced Power Management ---", 0xA, 0
    len_title   equ $-msg_title

    msg_check   db "Checking support...", 0xA, 0
    msg_no_sup  db "Function 80000007h not supported.", 0xA, 0

    ; Output messages
    msg_inv_tsc db "Invariant TSC (Constant Rate in all states): ", 0
    
    ; Raw value messages (Since most bits are reserved, seeing them is useful)
    msg_raw_edx db 0xA, "Raw EDX Value: 0x", 0

    str_yes     db "[Yes] (Supported)", 0xA, 0
    str_no      db "[No] (Not Supported)", 0xA, 0
    
    newline     db 0xA

section .bss
    HexBuf      resb 8
    RawEDX      resd 1

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
    cmp eax, 0x80000007
    jb .not_supported

    ; --- 2. Execute CPUID ---
    mov eax, 0x80000007
    cpuid
    mov [RawEDX], edx   ; According to Table 5-26, important info is in EDX

    ; --- 3. Check Invariant TSC Bit (Bit 8) ---
    ; 
    mov ecx, msg_inv_tsc
    mov edx, 45
    call print_string
    
    mov eax, [RawEDX]
    bt eax, 8           ; Test bit 8
    call print_yes_no

    ; --- 4. Print Raw EDX Value (to check other bits) ---
    mov ecx, msg_raw_edx
    mov edx, 18
    call print_string
    
    mov eax, [RawEDX]
    call print_hex
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

print_yes_no:
    jc .yes
    mov ecx, str_no
    mov edx, 21
    jmp .do_print
.yes:
    mov ecx, str_yes
    mov edx, 18
.do_print:
    mov eax, 4
    mov ebx, 1
    int 0x80
    ret

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