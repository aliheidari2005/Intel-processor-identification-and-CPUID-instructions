section .data
    ; Messages to print to output
    msg_supported db "System supports CPUID instruction!", 0xA
    len_supported equ $ - msg_supported

    msg_unsupported db "System DOES NOT support CPUID.", 0xA
    len_unsupported equ $ - msg_unsupported

section .text
    global _start

_start:
    ; --- Step 1: Get a copy of EFLAGS ---
    pushfd                  ; Push current EFLAGS value onto the Stack
    pop eax                 ; Pop it from Stack into EAX
    
    mov ecx, eax            ; Keep a copy of the original value in ECX (for final comparison)

    ; --- Step 2: Toggle Bit 21 (ID Flag) ---
    ; Bit 21 corresponds to hexadecimal 0x00200000
    xor eax, 0x00200000     ; Flip (Toggle) Bit 21

    ; --- Step 3: Write new value back to EFLAGS ---
    push eax                ; Push the modified value onto the Stack
    popfd                   ; Attempt to pop Stack value into EFLAGS register
                            ; (If CPU is old, Bit 21 won't change and remains as before)

    ; --- Step 4: Read EFLAGS again to verify ---
    pushfd                  ; Read EFLAGS again
    pop eax                 ; And store in EAX

    ; --- Step 5: Compare with original value ---
    xor eax, ecx            ; XOR new value with original value (stored in ECX)
    jz .no_cpuid            ; If zero, no bits changed -> CPUID not supported

    ; If we get here, Bit 21 has changed
    
    ; --- Print success message ---
    mov eax, 4              ; Syscall number sys_write
    mov ebx, 1              ; File descriptor stdout
    mov ecx, msg_supported  ; Message address
    mov edx, len_supported  ; Message length
    int 0x80                ; Kernel call

    jmp .exit

.no_cpuid:
    ; --- Print unsupported message ---
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_unsupported
    mov edx, len_unsupported
    int 0x80

.exit:
    ; --- Exit program ---
    mov eax, 1              ; Syscall number sys_exit
    xor ebx, ebx            ; Return code 0
    int 0x80