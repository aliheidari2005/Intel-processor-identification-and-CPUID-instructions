; ----------------------------------------------------------------------------------------
; Program to check Processor Serial Number (PSN)
; Input EAX=3 (Specific to Pentium III)
; ----------------------------------------------------------------------------------------

section .data
    msg_title   db "--- CPUID (EAX=3) Processor Serial Number ---", 0xA, 0
    len_title   equ $-msg_title

    msg_check   db "Checking PSN Feature Flag (Leaf 1, EDX Bit 18)...", 0xA, 0
    msg_yes     db "  [RESULT] Supported (PSN is Enabled).", 0xA, 0
    msg_no      db "  [RESULT] Not Supported / Disabled (Modern CPU).", 0xA, 0

    msg_raw     db 0xA, "Raw Output of Leaf 3:", 0xA, 0
    msg_ecx     db "  ECX (Bottom 32-bits): 0x", 0
    msg_edx     db "  EDX (Middle 32-bits): 0x", 0
    
    msg_sig     db "  Signature (Top 32-bits): 0x", 0
    
    msg_full    db 0xA, "Full 96-bit Serial: ", 0
    dash        db "-", 0
    
    newline     db 0xA

section .bss
    HexBuf      resb 8
    
    ; Storage for serial parts
    Sig_Top     resd 1  ; From EAX=1
    SN_Mid      resd 1  ; From EAX=3 EDX
    SN_Bot      resd 1  ; From EAX=3 ECX
    
    IsSupported resb 1  ; 1=Yes, 0=No

section .text
    global _start

_start:
    ; Print title
    mov ecx, msg_title
    mov edx, len_title
    call print_string

    ; =========================================================
    ; Step 1: Check Support (Feature Flag)
    ; According to page 51: Bit 18 of EDX register must be checked at input EAX=1.
    ; =========================================================
    mov ecx, msg_check
    mov edx, 46
    call print_string

    mov eax, 1
    cpuid
    
    mov [Sig_Top], eax  ; Save top 32 bits (Signature)
    
    ; Check bit 18 in EDX
    bt edx, 18          ; Bit Test
    jc .supported
    
    ; If not supported
    mov byte [IsSupported], 0
    mov ecx, msg_no
    mov edx, 48
    call print_string
    jmp .get_psn_data   ; However, we get the data to see (usually it is zero)

.supported:
    mov byte [IsSupported], 1
    mov ecx, msg_yes
    mov edx, 39
    call print_string

    ; =========================================================
    ; Step 2: Execute CPUID with EAX=3
    ; =========================================================
.get_psn_data:
    mov eax, 3
    cpuid
    
    ; According to page 20 (Figure 5-1):
    ; ECX = Bits 31-00 (Bottom)
    ; EDX = Bits 63-32 (Middle)
    
    mov [SN_Bot], ecx
    mov [SN_Mid], edx

    ; =========================================================
    ; Step 3: Print raw output
    ; =========================================================
    mov ecx, msg_raw
    mov edx, 23
    call print_string

    ; Print ECX
    mov ecx, msg_ecx
    mov edx, 24
    call print_string
    mov eax, [SN_Bot]
    call print_hex
    call print_newline

    ; Print EDX
    mov ecx, msg_edx
    mov edx, 24
    call print_string
    mov eax, [SN_Mid]
    call print_hex
    call print_newline
    
    ; Print Signature (captured earlier)
    mov ecx, msg_sig
    mov edx, 27
    call print_string
    mov eax, [Sig_Top]
    call print_hex
    call print_newline

    ; =========================================================
    ; Step 4: Print full format (XXXX-XXXX-XXXX)
    ; According to suggested format on page 52
    ; =========================================================
    mov ecx, msg_full
    mov edx, 21
    call print_string
    
    ; Print top part (Signature)
    mov eax, [Sig_Top]
    call print_hex_spaced ; Two separate 4-digit parts
    
    mov ecx, dash
    mov edx, 1
    call print_string
    
    ; Print middle part (EDX)
    mov eax, [SN_Mid]
    call print_hex_spaced
    
    mov ecx, dash
    mov edx, 1
    call print_string
    
    ; Print bottom part (ECX)
    mov eax, [SN_Bot]
    call print_hex_spaced
    
    call print_newline

    ; Exit
    mov eax, 1
    xor ebx, ebx
    int 0x80

; =========================================================
; Subroutines
; =========================================================

print_string:
    mov eax, 4
    mov ebx, 1
    int 0x80
    ret

print_newline:
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80
    ret

; Print 8 normal hex digits
print_hex:
    pushad
    mov ecx, 8
    mov edi, HexBuf
.loop:
    rol eax, 4
    mov bl, al
    and bl, 0x0F
    cmp bl, 9
    ja .let
    add bl, '0'
    jmp .store
.let:
    add bl, 'A' - 10
.store:
    mov [edi], bl
    inc edi
    dec ecx
    jnz .loop
    mov eax, 4
    mov ebx, 1
    mov ecx, HexBuf
    mov edx, 8
    int 0x80
    popad
    ret

; Print 8 hex digits in XXXX-XXXX format (for serial number format)
; Splits input number and inserts dash
print_hex_spaced:
    pushad
    mov esi, eax        ; Save original number
    
    ; Print top 4 digits (top 16 bits)
    shr eax, 16
    call print_hex_4
    
    ; Print dash
    push eax
    push ebx
    push ecx
    push edx
    mov eax, 4
    mov ebx, 1
    mov ecx, dash
    mov edx, 1
    int 0x80
    pop edx
    pop ecx
    pop ebx
    pop eax
    
    ; Print bottom 4 digits
    mov eax, esi
    and eax, 0xFFFF
    call print_hex_4
    
    popad
    ret

; Print only 4 hex digits (lower 16 bits of EAX)
print_hex_4:
    pushad
    mov ecx, 4          ; Only 4 digits
    mov edi, HexBuf
    
    shl eax, 16         ; Shift to appropriate position for rotation
.loop4:
    rol eax, 4
    mov bl, al
    and bl, 0x0F
    cmp bl, 9
    ja .let4
    add bl, '0'
    jmp .store4
.let4:
    add bl, 'A' - 10
.store4:
    mov [edi], bl
    inc edi
    dec ecx
    jnz .loop4
    mov eax, 4
    mov ebx, 1
    mov ecx, HexBuf
    mov edx, 4
    int 0x80
    popad
    ret