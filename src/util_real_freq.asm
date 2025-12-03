; =================================================================
; CPU Frequency Calculator (32-bit Assembly)
; Based on Intel Application Note 485 - FREQUENC.ASM (Page 122)
; Adapted for Linux 32-bit (Protected Mode)
;
; Logic:
; 1. Check CPUID for "GenuineIntel".
; 2. Check for TSC support (EDX bit 4).
; 3. Read Time-Stamp Counter (RDTSC) - Start.
; 4. Sleep for 1 second (Reference Period).
; 5. Read Time-Stamp Counter (RDTSC) - End.
; 6. Calculate Frequency = (End - Start) / Time.
; =================================================================

section .data
    msg_intro       db "Intel CPU Frequency Calculator (32-bit)", 0xA, 0
    msg_not_intel   db "Error: Not a GenuineIntel processor.", 0xA, 0
    msg_no_tsc      db "Error: RDTSC instruction not supported.", 0xA, 0
    msg_measuring   db "Measuring frequency (wait 1 second)...", 0xA, 0
    msg_result_pre  db "Detected Frequency: ", 0
    msg_result_suf  db " Hz", 0xA, 0
    newline         db 0xA, 0

    ; Data for sys_nanosleep (1 second wait)
    timespec:
        tv_sec  dd 1        ; 1 second
        tv_nsec dd 0        ; 0 nanoseconds
    
    rem_struct:             ; Remaining time struct (required for syscall)
        dd 0
        dd 0

section .bss
    tsc_start_low   resd 1
    tsc_start_high  resd 1
    tsc_end_low     resd 1
    tsc_end_high    resd 1
    freq_low        resd 1  ; Final frequency (low 32 bits)
    buffer          resb 16 ; Buffer for integer to string conversion

section .text
    global _start

_start:
    ; Print Intro
    mov eax, msg_intro
    call print_string

    ; -------------------------------------------------------------
    ; Step 1: Verify GenuineIntel
    ; -------------------------------------------------------------
    xor eax, eax            ; CPUID Function 0
    cpuid
    
    ; Check Vendor ID "GenuineIntel"
    ; EBX = 'Genu', EDX = 'ineI', ECX = 'ntel'
    cmp ebx, 0x756e6547     ; 'Genu'
    jne .not_intel
    cmp edx, 0x49656e69     ; 'ineI'
    jne .not_intel
    cmp ecx, 0x6c65746e     ; 'ntel'
    jne .not_intel

    ; -------------------------------------------------------------
    ; Step 2: Check Feature Flags (TSC Support)
    ; -------------------------------------------------------------
    mov eax, 1              ; CPUID Function 1
    cpuid
    bt edx, 4               ; Check Bit 4 of EDX (TSC Support)
    jnc .no_tsc             ; Jump if Carry Flag is not set (Bit was 0)

    ; -------------------------------------------------------------
    ; Step 3: Measurement Phase
    ; -------------------------------------------------------------
    mov eax, msg_measuring
    call print_string

    ; Read TSC (Start)
    ; rdtsc loads EDX:EAX with the cycle count
    rdtsc
    mov [tsc_start_low], eax
    mov [tsc_start_high], edx

    ; Wait for Reference Period (1 Second)
    ; Using sys_nanosleep (syscall 162)
    mov eax, 162            ; sys_nanosleep
    mov ebx, timespec       ; pointer to requested time
    mov ecx, rem_struct     ; pointer to remaining time
    int 0x80

    ; Read TSC (End)
    rdtsc
    mov [tsc_end_low], eax
    mov [tsc_end_high], edx

    ; -------------------------------------------------------------
    ; Step 4: Calculate Delta (End - Start)
    ; -------------------------------------------------------------
    ; 64-bit subtraction using 32-bit registers
    mov eax, [tsc_end_low]
    mov edx, [tsc_end_high]
    
    sub eax, [tsc_start_low]    ; Subtract low dwords
    sbb edx, [tsc_start_high]   ; Subtract high dwords with borrow
    
    ; Note: For a 1 second interval, the Delta IS the frequency in Hz.
    ; Result is in EDX:EAX. We will print the low 32 bits (EAX)
    ; because 32-bit unsigned max is ~4.29 GHz. 
    ; If CPU > 4.29 GHz, we would need 64-bit printing logic.
    ; Assuming EAX is sufficient for typical desktop CPUs < 4GHz for this demo.
    
    mov [freq_low], eax

    ; -------------------------------------------------------------
    ; Step 5: Print Result
    ; -------------------------------------------------------------
    mov eax, msg_result_pre
    call print_string

    mov eax, [freq_low]
    call print_int          ; Convert EAX to string and print

    mov eax, msg_result_suf
    call print_string

    jmp .exit

.not_intel:
    mov eax, msg_not_intel
    call print_string
    jmp .exit

.no_tsc:
    mov eax, msg_no_tsc
    call print_string
    jmp .exit

.exit:
    ; Exit syscall
    mov eax, 1              ; sys_exit
    xor ebx, ebx            ; status 0
    int 0x80

; =================================================================
; Helper Procedures
; =================================================================

; Procedure: print_string
; Input: EAX = Pointer to null-terminated string
print_string:
    pusha
    mov ecx, eax            ; string pointer
    
    ; Calculate length
    xor edx, edx
.strlen:
    cmp byte [ecx + edx], 0
    je .print
    inc edx
    jmp .strlen
.print:
    mov eax, 4              ; sys_write
    mov ebx, 1              ; stdout
    int 0x80
    popa
    ret

; Procedure: print_int
; Input: EAX = Unsigned Integer to print
; Converts integer in EAX to decimal string and prints it
print_int:
    pusha
    mov ecx, buffer         ; Buffer address
    add ecx, 15             ; Start at end of buffer
    mov byte [ecx], 0       ; Null terminator
    mov ebx, 10             ; Divisor

.convert_loop:
    dec ecx
    xor edx, edx            ; Clear EDX for division
    div ebx                 ; EAX / 10 -> Quotient in EAX, Remainder in EDX
    add dl, '0'             ; Convert remainder to ASCII
    mov [ecx], dl
    test eax, eax           ; Check if quotient is 0
    jnz .convert_loop

    mov eax, ecx            ; Move string start to EAX for printing
    call print_string
    popa
    ret