; ----------------------------------------------------------------------------------------
; Program to display MONITOR/MWAIT Info (CPUID EAX=5)
; Source: Application Note 485 - Table 5-11
; ----------------------------------------------------------------------------------------

section .data
    msg_title   db "--- CPUID (EAX=5) MONITOR/MWAIT Info ---", 0xA, 0
    len_title   equ $-msg_title

    ; EAX/EBX Messages (Line Sizes)
    msg_min     db "Smallest Monitor Line Size (bytes): ", 0
    msg_max     db "Largest  Monitor Line Size (bytes): ", 0

    ; ECX Messages (Features)
    msg_ext     db "Enumeration of Monitor-MWAIT extensions: ", 0
    msg_intr    db "Interrupts as break-event for MWAIT:     ", 0
    str_yes     db "Supported", 0xA, 0
    str_no      db "Not Supported", 0xA, 0

    ; EDX Messages (C-States)
    msg_cstate  db "Number of C-State sub-states supported:", 0xA, 0
    msg_c_prefix db "  > C", 0
    msg_c_suffix db " sub-states: ", 0

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

    ; --- 1. Execute CPUID with EAX=5 ---
    mov eax, 5
    cpuid
    
    mov [RawEAX], eax
    mov [RawEBX], ebx
    mov [RawECX], ecx
    mov [RawEDX], edx

    ; =========================================================
    ; 2. Process EAX and EBX (Line Sizes)
    ; According to Table 5-11: Bits 0 to 15 hold the value.
    ; =========================================================
    
    ; Print Smallest Line Size (EAX)
    mov ecx, msg_min
    mov edx, 36
    call print_string
    
    mov eax, [RawEAX]
    and eax, 0xFFFF     ; Only lower 16 bits are valid
    call print_decimal
    call print_newline

    ; Print Largest Line Size (EBX)
    mov ecx, msg_max
    mov edx, 36
    call print_string
    
    mov eax, [RawEBX]
    and eax, 0xFFFF     ; Only lower 16 bits are valid
    call print_decimal
    call print_newline
    call print_newline

    ; =========================================================
    ; 3. Process ECX (Features)
    ; =========================================================
    
    ; Check Bit 0 (Extensions Supported)
    mov ecx, msg_ext
    mov edx, 41
    call print_string
    
    mov eax, [RawECX]
    bt eax, 0           ; Test bit 0
    call print_yes_no

    ; Check Bit 1 (Interrupt Break-Event)
    mov ecx, msg_intr
    mov edx, 41
    call print_string
    
    mov eax, [RawECX]
    bt eax, 1           ; Test bit 1
    call print_yes_no
    call print_newline

    ; =========================================================
    ; 4. Process EDX (Number of C-State sub-states)
    ; According to table:
    ; Bits 0-3: C0, Bits 4-7: C1, ... Bits 16-19: C4
    ; =========================================================
    mov ecx, msg_cstate
    mov edx, 40
    call print_string

    mov esi, [RawEDX]   ; Keep EDX value in ESI
    xor edi, edi        ; Loop counter (0 to 4 for C0 to C4)

.cstate_loop:
    ; Print prefix "  > C"
    mov ecx, msg_c_prefix
    mov edx, 5
    call print_string
    
    ; Print C-State number (0, 1, 2...)
    mov eax, edi
    call print_decimal
    
    ; Print suffix " sub-states: "
    mov ecx, msg_c_suffix
    mov edx, 13
    call print_string
    
    ; Extract count (lower 4 bits of ESI)
    mov eax, esi
    and eax, 0x0F       ; Mask 4 bits
    call print_decimal
    call print_newline
    
    ; Prepare for next iteration
    shr esi, 4          ; Shift ESI to bring next C-State to bottom
    inc edi             ; Increment C-State number
    cmp edi, 5          ; Have we reached C5? (Only up to C4 is standard)
    jl .cstate_loop

    ; Exit
    mov eax, 1
    xor ebx, ebx
    int 0x80

; =========================================================
; Subroutines
; =========================================================

; --- print_yes_no ---
; Prints based on Carry Flag (set by 'bt' instruction)
print_yes_no:
    jc .yes
    mov ecx, str_no
    mov edx, 14
    jmp .do_print
.yes:
    mov ecx, str_yes
    mov edx, 10
.do_print:
    mov eax, 4
    mov ebx, 1
    int 0x80
    ret

; --- Previous standard functions ---
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