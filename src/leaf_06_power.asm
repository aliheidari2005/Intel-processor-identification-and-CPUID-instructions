; ----------------------------------------------------------------------------------------
; Program to display Thermal & Power Management Info (CPUID EAX=6)
; Source: Application Note 485 - Table 5-12
; ----------------------------------------------------------------------------------------

section .data
    msg_title   db "--- CPUID (EAX=6) Thermal & Power Mgmt ---", 0xA, 0
    len_title   equ $-msg_title

    ; EAX Messages (Capabilities)
    msg_dts     db "Digital Thermal Sensor (DTS):    ", 0
    msg_turbo   db "Intel Turbo Boost Technology:      ", 0
    msg_arat    db "Always Running APIC Timer (ARAT):  ", 0
    msg_pln     db "Power Limit Notification (PLN):    ", 0
    msg_ptm     db "Package Thermal Management (PTM):  ", 0

    ; EBX Messages
    msg_thresh  db 0xA, "Number of Interrupt Thresholds:    ", 0

    ; ECX Messages
    msg_perf    db 0xA, "Hardware Coordination Feedback:    ", 0
    msg_bias    db "Performance-Energy Bias Capability:", 0

    str_yes     db "[Yes]", 0xA, 0
    str_no      db "[No]", 0xA, 0

    newline     db 0xA

section .bss
    DecBuf      resb 10
    RawEAX      resd 1
    RawEBX      resd 1
    RawECX      resd 1
    RawEDX      resd 1

section .text
    global _start

_start:
    ; Print title
    mov ecx, msg_title
    mov edx, len_title
    call print_string

    ; --- 1. Execute CPUID with EAX=6 ---
    mov eax, 6
    cpuid
    
    mov [RawEAX], eax
    mov [RawEBX], ebx
    mov [RawECX], ecx
    mov [RawEDX], edx

    ; =========================================================
    ; 2. Process EAX (Main Flags)
    ; According to Table 5-12 [Source: 656]
    ; =========================================================
    
    ; Bit 0: Digital Thermal Sensor
    mov ecx, msg_dts
    mov edx, 35
    call print_string
    mov eax, [RawEAX]
    bt eax, 0
    call print_yes_no

    ; Bit 1: Turbo Boost
    mov ecx, msg_turbo
    mov edx, 35
    call print_string
    mov eax, [RawEAX]
    bt eax, 1
    call print_yes_no

    ; Bit 2: ARAT
    mov ecx, msg_arat
    mov edx, 35
    call print_string
    mov eax, [RawEAX]
    bt eax, 2
    call print_yes_no

    ; Bit 4: PLN
    mov ecx, msg_pln
    mov edx, 35
    call print_string
    mov eax, [RawEAX]
    bt eax, 4
    call print_yes_no

    ; Bit 6: PTM
    mov ecx, msg_ptm
    mov edx, 35
    call print_string
    mov eax, [RawEAX]
    bt eax, 6
    call print_yes_no

    ; =========================================================
    ; 3. Process EBX (Number of Thresholds)
    ; According to Table 5-12: Bits 0 to 3
    ; =========================================================
    mov ecx, msg_thresh
    mov edx, 36
    call print_string
    
    mov eax, [RawEBX]
    and eax, 0x0F       ; Only lower 4 bits
    call print_decimal
    call print_newline

    ; =========================================================
    ; 4. Process ECX (Energy Capabilities)
    ; According to Table 5-12 [Source: 662]
    ; =========================================================
    
    ; Bit 0: Hardware Coordination Feedback
    mov ecx, msg_perf
    mov edx, 36
    call print_string
    mov eax, [RawECX]
    bt eax, 0
    call print_yes_no

    ; Bit 3: Performance-Energy Bias
    mov ecx, msg_bias
    mov edx, 35
    call print_string
    mov eax, [RawECX]
    bt eax, 3
    call print_yes_no

    ; Exit
    mov eax, 1
    xor ebx, ebx
    int 0x80

; =========================================================
; Subroutines
; =========================================================

; --- print_yes_no ---
; Prints based on Carry Flag
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

; --- Previous standard functions ---
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