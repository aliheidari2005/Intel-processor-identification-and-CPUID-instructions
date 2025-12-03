; ----------------------------------------------------------------------------------------
; Program to display Direct Cache Access info (CPUID EAX=9)
; Source: Application Note 485 - Table 5-14
; ----------------------------------------------------------------------------------------

section .data
    msg_title   db "--- CPUID (EAX=9) Direct Cache Access (DCA) ---", 0xA, 0
    len_title   equ $-msg_title

    msg_check   db "Checking if Leaf 9 is supported...", 0xA, 0
    
    msg_eax     db "Value of PLATFORM_DCA_CAP MSR [Bits 31:0]: 0x", 0
    
    msg_res     db 0xA, "Note: EBX, ECX, EDX are reserved in this leaf.", 0xA, 0
    
    msg_not_sup db "Leaf 9 is NOT supported on this processor (Max Standard Leaf < 9).", 0xA, 0

    newline     db 0xA

section .bss
    HexBuf      resb 8      ; Hex print buffer
    MaxFunc     resd 1      ; Maximum supported function
    RawEAX      resd 1

section .text
    global _start

_start:
    ; Print title
    mov ecx, msg_title
    mov edx, len_title
    call print_string

    ; --- 1. Check support (Does the processor have Leaf 9?) ---
    mov ecx, msg_check
    mov edx, 37
    call print_string

    mov eax, 0          ; Get maximum standard function
    cpuid
    mov [MaxFunc], eax
    
    cmp eax, 9          ; Is max less than 9?
    jl .not_supported

    ; --- 2. Execute CPUID with EAX=9 ---
    mov eax, 9
    cpuid
    mov [RawEAX], eax   ; Only EAX contains valid data

    ; --- 3. Print EAX value ---
    mov ecx, msg_eax
    mov edx, 43
    call print_string
    
    mov eax, [RawEAX]
    call print_hex      ; Print hex value
    call print_newline
    
    ; Message about others being reserved
    mov ecx, msg_res
    mov edx, 44
    call print_string
    
    jmp .exit

.not_supported:
    mov ecx, msg_not_sup
    mov edx, 67
    call print_string

.exit:
    ; Exit
    mov eax, 1
    xor ebx, ebx
    int 0x80

; =========================================================
; Subroutines (Same as before)
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