; ----------------------------------------------------------------------------------------
; Program to display Extended Functions
; Check 64-bit support, security features, and extract full processor brand string
; Source: Application Note 485 - Section 5.2
; ----------------------------------------------------------------------------------------

section .data
    msg_title   db "--- CPUID Extended Functions Info ---", 0xA, 0
    len_title   equ $-msg_title

    ; Messages for 80000000h
    msg_max     db "Max Extended Function Supported: 0x", 0

    ; Messages for 80000001h (Features)
    msg_feat    db 0xA, "Extended Features (Leaf 80000001h):", 0xA, 0
    msg_64bit   db "  [Bit 29] Intel 64 / AMD64 (Long Mode): ", 0
    msg_syscall db "  [Bit 11] SYSCALL/SYSRET Instructions:  ", 0
    msg_xd      db "  [Bit 20] Execute Disable (XD) Bit:     ", 0
    msg_1gb     db "  [Bit 26] 1GB Pages Support:            ", 0
    msg_rdtscp  db "  [Bit 27] RDTSCP Instruction:           ", 0
    msg_lahf    db "  [ECX Bit 0] LAHF/SAHF in 64-bit mode:  ", 0

    ; Brand String Messages
    msg_brand   db 0xA, "Processor Brand String:", 0xA, "  ", 0
    
    str_yes     db "[Yes]", 0xA, 0
    str_no      db "[No]", 0xA, 0
    
    msg_err     db "Extended functions not supported on this CPU.", 0xA, 0

    newline     db 0xA

section .bss
    HexBuf      resb 8
    MaxExt      resd 1
    BrandBuf    resb 49     ; 48 bytes + 1 null

section .text
    global _start

_start:
    ; Print title
    mov ecx, msg_title
    mov edx, len_title
    call print_string

    ; =========================================================
    ; 1. Check Maximum Extended Function (EAX = 80000000h)
    ; 
    ; =========================================================
    mov eax, 0x80000000
    cpuid
    
    ; If EAX is less than or equal to 80000000, it is not supported
    cmp eax, 0x80000000
    jbe .not_supported
    
    mov [MaxExt], eax   ; Save maximum (e.g., 80000008h)

    ; Print maximum
    mov ecx, msg_max
    mov edx, 35
    call print_string
    mov eax, [MaxExt]
    call print_hex
    call print_newline

    ; =========================================================
    ; 2. Extended Features (EAX = 80000001h)
    ; 
    ; =========================================================
    mov eax, [MaxExt]
    cmp eax, 0x80000001
    jb .skip_features

    mov ecx, msg_feat
    mov edx, 36
    call print_string

    mov eax, 0x80000001
    cpuid
    ; Important output is in EDX and ECX

    ; Check EDX Bit 29: Intel 64 (64-bit)
    ;
    push edx            ; Save EDX
    mov ecx, msg_64bit
    mov edx, 39
    call print_string
    pop edx             ; Restore EDX
    bt edx, 29
    call print_yes_no

    ; Check EDX Bit 11: SYSCALL
    ;
    push edx
    mov ecx, msg_syscall
    mov edx, 39
    call print_string
    pop edx
    bt edx, 11
    call print_yes_no

    ; Check EDX Bit 20: XD Bit (Security against buffer overflow)
    ;
    push edx
    mov ecx, msg_xd
    mov edx, 39
    call print_string
    pop edx
    bt edx, 20
    call print_yes_no
    
    ; Check EDX Bit 26: 1GB Pages
    ;
    push edx
    mov ecx, msg_1gb
    mov edx, 39
    call print_string
    pop edx
    bt edx, 26
    call print_yes_no

    ; Check EDX Bit 27: RDTSCP
    ;
    push edx
    mov ecx, msg_rdtscp
    mov edx, 39
    call print_string
    pop edx
    bt edx, 27
    call print_yes_no

    ; Check ECX Bit 0: LAHF/SAHF
    ;
    ; (Note: ECX was initialized in the previous cpuid instruction)
    ; But since our print functions modify registers, it is better to execute again or save it.
    ; Here we execute again for simplicity:
    push eax            ; Save EAX (if needed)
    mov eax, 0x80000001
    cpuid
    pop eax
    
    push ecx            ; Save ECX for testing
    mov ecx, msg_lahf
    mov edx, 39
    call print_string
    pop ecx             ; Restore ECX
    bt ecx, 0
    call print_yes_no

.skip_features:

    ; =========================================================
    ; 3. Processor Brand String
    ; Inputs 80000002h, 80000003h, 80000004h
    ;
    ; =========================================================
    mov eax, [MaxExt]
    cmp eax, 0x80000004
    jb .skip_brand

    mov ecx, msg_brand
    mov edx, 26
    call print_string

    ; First part (16 bytes)
    mov eax, 0x80000002
    cpuid
    mov [BrandBuf], eax
    mov [BrandBuf+4], ebx
    mov [BrandBuf+8], ecx
    mov [BrandBuf+12], edx

    ; Second part (16 bytes)
    mov eax, 0x80000003
    cpuid
    mov [BrandBuf+16], eax
    mov [BrandBuf+20], ebx
    mov [BrandBuf+24], ecx
    mov [BrandBuf+28], edx

    ; Third part (16 bytes)
    mov eax, 0x80000004
    cpuid
    mov [BrandBuf+32], eax
    mov [BrandBuf+36], ebx
    mov [BrandBuf+40], ecx
    mov [BrandBuf+44], edx
    
    mov byte [BrandBuf+48], 0   ; Null terminator

    ; Print string (removing leading spaces)
    mov esi, BrandBuf
.trim_space:
    cmp byte [esi], ' ' ; Is it a space character?
    jne .print_brand
    inc esi             ; Go to next
    jmp .trim_space

.print_brand:
    mov ecx, esi        ; Text start address (after spaces)
    mov edx, 48         ; Length (approximate, OS prints until null)
    call print_string
    call print_newline
    
    jmp .exit

.skip_brand:
.not_supported:
    mov ecx, msg_err
    mov edx, 44
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
    mov edx, 5
    jmp .do_print
.yes:
    mov ecx, str_yes
    mov edx, 6
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