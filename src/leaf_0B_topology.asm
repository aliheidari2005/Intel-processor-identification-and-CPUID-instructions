; ----------------------------------------------------------------------------------------
; Program to display Extended Processor Topology (CPUID EAX=0Bh)
; Source: Application Note 485 - Tables 5-16 to 5-19
; ----------------------------------------------------------------------------------------

section .data
    msg_title   db "--- CPUID (EAX=0Bh) Extended Topology Info ---", 0xA, 0
    len_title   equ $-msg_title

    msg_level   db 0xA, "=== Level Index (ECX): ", 0
    msg_type    db "  Level Type: ", 0
    msg_count   db "  Logical Processors at this Level: ", 0
    msg_shift   db "  Level Shift (Right shift count):  ", 0
    msg_x2apic  db "  x2APIC ID (Current Logical CPU):  ", 0

    ; Name of Level Types
    str_invalid db "Invalid (0)", 0
    str_thread  db "SMT / Thread (1)", 0
    str_core    db "Core (2)", 0
    str_die     db "Die (Module) (3)", 0    ; In some newer processors
    str_pkg     db "Package (Tile) (4)", 0  ; In some newer processors
    str_unk     db "Unknown Type", 0

    newline     db 0xA
    colon       db ": ", 0

section .bss
    DecBuf      resb 10
    RawEAX      resd 1
    RawEBX      resd 1
    RawECX      resd 1
    RawEDX      resd 1
    CurrentECX  resd 1      ; Loop counter

section .text
    global _start

_start:
    ; Print title
    mov ecx, msg_title
    mov edx, len_title
    call print_string

    ; Check support: If max function is less than 0Bh, not supported
    mov eax, 0
    cpuid
    cmp eax, 0x0B
    jl .exit

    ; Start loop on ECX from 0
    mov dword [CurrentECX], 0

.topology_loop:
    ; Execute CPUID with EAX=0Bh and ECX=CurrentECX
    mov eax, 0x0B
    mov ecx, [CurrentECX]
    cpuid

    mov [RawEAX], eax
    mov [RawEBX], ebx
    mov [RawECX], ecx
    mov [RawEDX], edx

    ; Exit condition: If EAX=0 and EBX=0, we reached the end of the list
    ; (According to doc: "until EAX=0 and EBX=0")
    cmp eax, 0
    jne .process_level
    cmp ebx, 0
    je .exit            ; Both are zero -> Exit

.process_level:
    ; 1. Print index number (ECX)
    mov ecx, msg_level
    mov edx, 24
    call print_string
    mov eax, [CurrentECX]
    call print_decimal
    call print_newline

    ; 2. Print Level Type (ECX Bits 8-15)
    mov ecx, msg_type
    mov edx, 14
    call print_string
    
    mov eax, [RawECX]
    shr eax, 8
    and eax, 0xFF
    call print_level_type
    call print_newline

    ; 3. Print number of logical processors (EBX Bits 0-15)
    mov ecx, msg_count
    mov edx, 36
    call print_string
    
    mov eax, [RawEBX]
    and eax, 0xFFFF
    call print_decimal
    call print_newline

    ; 4. Print Level Shift (EAX Bits 0-4)
    ; Number of bits to shift to get the next level ID
    mov ecx, msg_shift
    mov edx, 36
    call print_string
    
    mov eax, [RawEAX]
    and eax, 0x1F
    call print_decimal
    call print_newline

    ; 5. Print x2APIC ID (EDX - full 32 bits)
    mov ecx, msg_x2apic
    mov edx, 36
    call print_string
    
    mov eax, [RawEDX]
    call print_decimal
    call print_newline

    ; Increment counter and continue loop
    inc dword [CurrentECX]
    jmp .topology_loop

.exit:
    mov eax, 1
    xor ebx, ebx
    int 0x80

; =========================================================
; Subroutines
; =========================================================

; --- print_level_type ---
; Input: EAX = Level type (number)
print_level_type:
    cmp eax, 0
    je .type_inv
    cmp eax, 1
    je .type_smt
    cmp eax, 2
    je .type_core
    cmp eax, 3
    je .type_die    ; Might not be in some docs but is a newer standard
    cmp eax, 4
    je .type_pkg
    
    ; Unknown type
    mov ecx, str_unk
    mov edx, 12
    jmp .do_print

.type_inv:
    mov ecx, str_invalid
    mov edx, 11
    jmp .do_print
.type_smt:
    mov ecx, str_thread
    mov edx, 16
    jmp .do_print
.type_core:
    mov ecx, str_core
    mov edx, 8
    jmp .do_print
.type_die:
    mov ecx, str_die
    mov edx, 16
    jmp .do_print
.type_pkg:
    mov ecx, str_pkg
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