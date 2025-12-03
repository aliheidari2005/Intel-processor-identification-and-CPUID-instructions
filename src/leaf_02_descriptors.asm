; ----------------------------------------------------------------------------------------
; Program to display Cache Descriptors info (CPUID EAX=2)
; This program extracts and prints descriptor bytes from registers.
; ----------------------------------------------------------------------------------------

section .data
    msg_title   db "--- CPUID (EAX=2) Cache/TLB Descriptors ---", 0xA, 0
    len_title   equ $-msg_title

    msg_iter    db "Iteration Count (AL): ", 0
    
    msg_desc    db "Descriptor Byte: 0x", 0
    
    msg_reg_eax db 0xA, "[EAX Bytes]: ", 0
    msg_reg_ebx db 0xA, "[EBX Bytes]: ", 0
    msg_reg_ecx db 0xA, "[ECX Bytes]: ", 0
    msg_reg_edx db 0xA, "[EDX Bytes]: ", 0
    
    newline     db 0xA
    comma       db ", ", 0

section .bss
    HexBuf      resb 8      ; Hex print buffer
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

    ; --- 1. Execute CPUID with EAX=2 ---
    mov eax, 2
    cpuid
    
    ; Save raw values
    mov [RawEAX], eax
    mov [RawEBX], ebx
    mov [RawECX], ecx
    mov [RawEDX], edx

    ; --- 2. Print Iteration Count (AL) ---
    ; According to docs, lower byte of EAX is the number of times to call (usually 1)
    mov ecx, msg_iter
    mov edx, 22
    call print_string
    
    mov eax, [RawEAX]
    and eax, 0xFF       ; Only AL
    call print_hex_byte ; Print as hex (e.g., 01)
    call print_newline

    ; =========================================================
    ; Process and print Descriptor Bytes
    ; We must scan each register byte by byte (from top to bottom).
    ; =========================================================

    ; --- Process EAX ---
    ; Note: The lower byte of EAX (AL) is not a descriptor, it's a counter. 
    ; So we only print the top 3 bytes.
    mov ecx, msg_reg_eax
    mov edx, 14
    call print_string
    
    mov eax, [RawEAX]
    
    ; Byte 4 (MSB) - Bits 31-24
    mov ebx, eax
    shr ebx, 24
    call check_and_print_byte
    
    ; Byte 3 - Bits 23-16
    mov ebx, eax
    shr ebx, 16
    and ebx, 0xFF
    call check_and_print_byte
    
    ; Byte 2 - Bits 15-8
    mov ebx, eax
    shr ebx, 8
    and ebx, 0xFF
    call check_and_print_byte
    ; (Byte 1 is ignored)

    ; --- Process EBX ---
    mov ecx, msg_reg_ebx
    mov edx, 14
    call print_string
    
    ; Check Valid Bit - Bit 31 must not be 1
    mov eax, [RawEBX]
    test eax, 0x80000000
    jnz .skip_ebx       ; If bit 31 is set, this register is not valid
    
    mov ebx, eax        ; Copy for processing
    call process_full_register
.skip_ebx:

    ; --- Process ECX ---
    mov ecx, msg_reg_ecx
    mov edx, 14
    call print_string
    
    mov eax, [RawECX]
    test eax, 0x80000000
    jnz .skip_ecx
    
    mov ebx, eax
    call process_full_register
.skip_ecx:

    ; --- Process EDX ---
    mov ecx, msg_reg_edx
    mov edx, 14
    call print_string
    
    mov eax, [RawEDX]
    test eax, 0x80000000
    jnz .skip_edx
    
    mov ebx, eax
    call process_full_register
.skip_edx:

    call print_newline
    
    ; Exit
    mov eax, 1
    xor ebx, ebx
    int 0x80

; =========================================================
; Subroutines
; =========================================================

; --- process_full_register ---
; Input: EBX (Full register value)
; Separates and prints every 4 bytes
process_full_register:
    push eax
    push ebx
    
    ; Byte 4
    mov eax, ebx
    shr eax, 24
    call check_and_print_byte
    
    ; Byte 3
    mov eax, ebx
    shr eax, 16
    and eax, 0xFF
    call check_and_print_byte
    
    ; Byte 2
    mov eax, ebx
    shr eax, 8
    and eax, 0xFF
    call check_and_print_byte
    
    ; Byte 1
    mov eax, ebx
    and eax, 0xFF
    call check_and_print_byte
    
    pop ebx
    pop eax
    ret

; --- check_and_print_byte ---
; Input: EAX (Target byte in the lowest part)
; If byte is 00 (Null Descriptor), do not print.
check_and_print_byte:
    cmp al, 0x00        ; Is it a null descriptor?
    je .done            ; If yes, do not print
    
    push eax
    call print_hex_byte ; Print hex value (e.g., 76)
    
    mov ecx, comma
    mov edx, 2
    call print_string
    pop eax
    
.done:
    ret

; --- Standard helper functions (like previous codes) ---
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

; Print 2 hex digits (one byte) present in AL
print_hex_byte:
    pushad
    mov ecx, 2          ; 2 digits
    mov edi, HexBuf
    
    ; Shift EAX up so the target byte is in the right position for the generic algorithm
    shl eax, 24         
    
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
    mov edx, 2
    int 0x80
    popad
    ret