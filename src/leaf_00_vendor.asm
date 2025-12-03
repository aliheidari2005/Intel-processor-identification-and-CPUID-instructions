section .data
    msg_vendor  db "Vendor String: ", 0
    len_vendor  equ $-msg_vendor
    
    msg_eax     db "EAX Value: 0x", 0
    len_eax     equ $-msg_eax
    
    msg_ebx     db "EBX Value: 0x", 0
    len_ebx     equ $-msg_ebx
    
    msg_ecx     db "ECX Value: 0x", 0
    len_ecx     equ $-msg_ecx
    
    msg_edx     db "EDX Value: 0x", 0
    len_edx     equ $-msg_edx

    newline     db 0xA

section .bss
    VendorBuf   resb 13     ; Buffer for text string
    HexBuf      resb 8      ; Buffer for number to hex conversion (8 digits)

section .text
    global _start

_start:
    ; --- 1. Execute CPUID ---
    mov eax, 0
    cpuid

    ; --- 2. Save results on the stack (since we need registers for printing) ---
    push edx        ; Save EDX
    push ecx        ; Save ECX
    push ebx        ; Save EBX
    push eax        ; Save EAX

    ; --- 3. Construct and print Vendor ID string (text part) ---
    mov [VendorBuf], ebx
    mov [VendorBuf+4], edx
    mov [VendorBuf+8], ecx
    
    ; Print title
    mov ecx, msg_vendor
    mov edx, len_vendor
    call print_string
    
    ; Print string value
    mov ecx, VendorBuf
    mov edx, 12
    call print_string
    call print_newline

    ; --- 4. Print EAX (Restore from stack) ---
    pop eax         ; Restore EAX value
    
    push eax        ; (Temporary save so the print function doesn't corrupt registers if needed)
    mov ecx, msg_eax
    mov edx, len_eax
    call print_string
    pop eax         ; Restore value for conversion
    call print_hex  ; Convert and print
    call print_newline

    ; --- 5. Print EBX ---
    pop eax         ; Actually loading EBX into EAX to print (since it is the next pop)
    
    push eax
    mov ecx, msg_ebx
    mov edx, len_ebx
    call print_string
    pop eax
    call print_hex
    call print_newline

    ; --- 6. Print ECX ---
    pop eax         ; ECX value (popped into EAX for printing)
    
    push eax
    mov ecx, msg_ecx
    mov edx, len_ecx
    call print_string
    pop eax
    call print_hex
    call print_newline

    ; --- 7. Print EDX ---
    pop eax         ; EDX value
    
    push eax
    mov ecx, msg_edx
    mov edx, len_edx
    call print_string
    pop eax
    call print_hex
    call print_newline

    ; --- Exit ---
    mov eax, 1      ; sys_exit
    xor ebx, ebx
    int 0x80

; ------------------------------------------------------------------
; Subroutine: print_string
; Input: ECX = Text Address, EDX = Text Length
; ------------------------------------------------------------------
print_string:
    mov eax, 4      ; sys_write
    mov ebx, 1      ; stdout
    int 0x80
    ret

; ------------------------------------------------------------------
; Subroutine: print_newline
; Prints a newline character
; ------------------------------------------------------------------
print_newline:
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80
    ret

; ------------------------------------------------------------------
; Subroutine: print_hex
; Converts number in EAX to 8-digit hex string and prints it
; Algorithm: 4-bit rotation (Nibble) and conversion to ASCII
; ------------------------------------------------------------------
print_hex:
    pushad              ; Save all registers
    mov ecx, 8          ; We have 8 hex digits (32 bits)
    mov edi, HexBuf     ; Output buffer address

convert_loop:
    rol eax, 4          ; Rotate top 4 bits to bottom (e.g., 0x1234 -> 0x2341)
    mov bl, al          ; Copy lower byte
    and bl, 0x0F        ; Keep only lower 4 bits (one hex digit)

    cmp bl, 9           ; Is it greater than 9? (i.e., A-F)
    ja is_hex_letter

    add bl, '0'         ; Convert 0-9 to ASCII code
    jmp store_char

is_hex_letter:
    add bl, 'A' - 10    ; Convert 10-15 to A-F

store_char:
    mov [edi], bl       ; Store in buffer
    inc edi             ; Advance buffer pointer
    dec ecx             ; Decrement loop counter
    jnz convert_loop    ; Continue if not zero

    ; Print converted buffer
    mov eax, 4
    mov ebx, 1
    mov ecx, HexBuf
    mov edx, 8
    int 0x80

    popad               ; Restore registers
    ret