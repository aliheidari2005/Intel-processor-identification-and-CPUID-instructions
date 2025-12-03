; ----------------------------------------------------------------------------------------
; Program to display Performance Monitoring capabilities (CPUID EAX=0Ah)
; Source: Application Note 485 - Table 5-15
; ----------------------------------------------------------------------------------------

section .data
    msg_title   db "--- CPUID (EAX=0Ah) Performance Monitoring ---", 0xA, 0
    len_title   equ $-msg_title

    ; EAX Messages
    msg_ver     db "Version ID: ", 0
    msg_gp_num  db "Number of GP Counters per Logical Core: ", 0
    msg_gp_wid  db "Bit Width of GP Counters: ", 0
    msg_vec_len db "Length of EBX Bit Vector: ", 0

    ; EBX Messages (Events)
    msg_events  db 0xA, "Architectural Events Supported (0=Yes, 1=No):", 0xA, 0
    msg_evt_0   db "  [Bit 0] Core Cycles:                 ", 0
    msg_evt_1   db "  [Bit 1] Instructions Retired:        ", 0
    msg_evt_2   db "  [Bit 2] Reference Cycles:            ", 0
    msg_evt_3   db "  [Bit 3] Last Level Cache References: ", 0
    msg_evt_4   db "  [Bit 4] Last Level Cache Misses:     ", 0
    msg_evt_5   db "  [Bit 5] Branch Instructions Retired: ", 0
    msg_evt_6   db "  [Bit 6] Branch Mispredicts Retired:  ", 0

    ; EDX Messages (Fixed Counters)
    msg_fix_num db 0xA, "Number of Fixed Counters:    ", 0
    msg_fix_wid db "Bit Width of Fixed Counters: ", 0

    str_sup     db "[Supported]", 0xA, 0
    str_unsup   db "[Not Supported]", 0xA, 0
    
    msg_no_pm   db "Performance Monitoring not supported (Version ID = 0).", 0xA, 0

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

    ; --- 1. Check general support ---
    mov eax, 0
    cpuid
    cmp eax, 0x0A       ; Is the maximum function ID less than 10?
    jl .not_supported

    ; --- 2. Execute CPUID with EAX=0Ah ---
    mov eax, 0x0A
    cpuid
    
    mov [RawEAX], eax
    mov [RawEBX], ebx
    mov [RawECX], ecx
    mov [RawEDX], edx

    ; Check Version ID (EAX bits 0-7)
    mov eax, [RawEAX]
    and eax, 0xFF
    cmp eax, 0
    je .not_supported   ; If version is 0, it means not supported

    ; =========================================================
    ; 3. Process EAX (General Specifications)
    ; =========================================================
    
    ; Version ID
    mov ecx, msg_ver
    mov edx, 12
    call print_string
    mov eax, [RawEAX]
    and eax, 0xFF
    call print_decimal
    call print_newline

    ; Num GP Counters (8-15)
    mov ecx, msg_gp_num
    mov edx, 40
    call print_string
    mov eax, [RawEAX]
    shr eax, 8
    and eax, 0xFF
    call print_decimal
    call print_newline

    ; GP Counter Width (16-23)
    mov ecx, msg_gp_wid
    mov edx, 26
    call print_string
    mov eax, [RawEAX]
    shr eax, 16
    and eax, 0xFF
    call print_decimal
    call print_newline

    ; EBX Vector Length (24-31)
    mov ecx, msg_vec_len
    mov edx, 26
    call print_string
    mov eax, [RawEAX]
    shr eax, 24
    and eax, 0xFF
    call print_decimal
    call print_newline

    ; =========================================================
    ; 4. Process EBX (Event Vector)
    ; 0 = Supported, 1 = Not Available
    ; =========================================================
    mov ecx, msg_events
    mov edx, 46
    call print_string

    ; Bit 0: Core Cycles
    mov ecx, msg_evt_0
    mov edx, 39
    call print_string
    mov eax, [RawEBX]
    bt eax, 0
    call print_event_status

    ; Bit 1: Instructions Retired
    mov ecx, msg_evt_1
    mov edx, 39
    call print_string
    mov eax, [RawEBX]
    bt eax, 1
    call print_event_status

    ; Bit 2: Reference Cycles
    mov ecx, msg_evt_2
    mov edx, 39
    call print_string
    mov eax, [RawEBX]
    bt eax, 2
    call print_event_status

    ; Bit 3: LLC References
    mov ecx, msg_evt_3
    mov edx, 39
    call print_string
    mov eax, [RawEBX]
    bt eax, 3
    call print_event_status

    ; Bit 4: LLC Misses
    mov ecx, msg_evt_4
    mov edx, 39
    call print_string
    mov eax, [RawEBX]
    bt eax, 4
    call print_event_status

    ; Bit 5: Branch Instructions
    mov ecx, msg_evt_5
    mov edx, 39
    call print_string
    mov eax, [RawEBX]
    bt eax, 5
    call print_event_status

    ; Bit 6: Branch Mispredicts
    mov ecx, msg_evt_6
    mov edx, 39
    call print_string
    mov eax, [RawEBX]
    bt eax, 6
    call print_event_status

    ; =========================================================
    ; 5. Process EDX (Fixed Counters)
    ; =========================================================
    
    ; Num Fixed Counters (0-4)
    mov ecx, msg_fix_num
    mov edx, 30
    call print_string
    mov eax, [RawEDX]
    and eax, 0x1F       ; Lower 5 bits
    call print_decimal
    call print_newline

    ; Fixed Counter Width (5-12)
    mov ecx, msg_fix_wid
    mov edx, 29
    call print_string
    mov eax, [RawEDX]
    shr eax, 5
    and eax, 0xFF       ; Next 8 bits
    call print_decimal
    call print_newline
    
    jmp .exit

.not_supported:
    mov ecx, msg_no_pm
    mov edx, 52
    call print_string

.exit:
    mov eax, 1
    xor ebx, ebx
    int 0x80

; =========================================================
; Subroutines
; =========================================================

; --- print_event_status ---
; Reverse of usual logic: If Carry=0 (Bit 0) -> Supported
; If Carry=1 (Bit 1) -> Not Supported
print_event_status:
    jc .no
    mov ecx, str_sup
    mov edx, 12
    jmp .do_print
.no:
    mov ecx, str_unsup
    mov edx, 16
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