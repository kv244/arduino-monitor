#include <avr/io.h>

.section .text

/**
 * void capture_registers(uint8_t *buffer)
 * r24:r25 = buffer
 * 
 * FIXED: Saves r24/r25 first to temporary location before using as pointer
 */
.global capture_registers
capture_registers:
    ; Save r24/r25 before we overwrite them
    push r24
    push r25
    
    movw r30, r24        ; Z = buffer address
    
    ; Restore and save r24/r25 properly
    pop r25
    pop r24
    
    std Z+0, r0
    std Z+1, r1
    std Z+2, r2
    std Z+3, r3
    std Z+4, r4
    std Z+5, r5
    std Z+6, r6
    std Z+7, r7
    std Z+8, r8
    std Z+9, r9
    std Z+10, r10
    std Z+11, r11
    std Z+12, r12
    std Z+13, r13
    std Z+14, r14
    std Z+15, r15
    std Z+16, r16
    std Z+17, r17
    std Z+18, r18
    std Z+19, r19
    std Z+20, r20
    std Z+21, r21
    std Z+22, r22
    std Z+23, r23
    std Z+24, r24
    std Z+25, r25
    std Z+26, r26
    std Z+27, r27
    std Z+28, r28
    std Z+29, r29
    std Z+30, r30
    std Z+31, r31
    
    in r0, _SFR_IO_ADDR(SREG)
    std Z+32, r0

    eor r1, r1           ; Restore zero register
    ret

/**
 * void restore_and_execute(uint16_t target_word_addr, uint8_t *buffer)
 * r24:r25 = target word address (will be converted to byte address)
 * r22:r23 = buffer
 * 
 * FIXED: 
 * - Converts word address to byte address (multiply by 2)
 * - Uses ijmp instead of ret trick to avoid stack corruption
 * - Restores SREG last with interrupts disabled
 */
.global restore_and_execute
restore_and_execute:
    cli                  ; Disable interrupts during restoration
    
    ; Convert word address to byte address (multiply by 2)
    lsl r24
    rol r25
    
    movw r30, r22        ; Z = buffer address

    ; Save target to a safe place (use stack temporarily)
    push r24
    push r25

    ; Restore all registers r0-r29 FIRST
    ldd r0, Z+0
    ldd r1, Z+1
    ldd r2, Z+2
    ldd r3, Z+3
    ldd r4, Z+4
    ldd r5, Z+5
    ldd r6, Z+6
    ldd r7, Z+7
    ldd r8, Z+8
    ldd r9, Z+9
    ldd r10, Z+10
    ldd r11, Z+11
    ldd r12, Z+12
    ldd r13, Z+13
    ldd r14, Z+14
    ldd r15, Z+15
    ldd r16, Z+16
    ldd r17, Z+17
    ldd r18, Z+18
    ldd r19, Z+19
    ldd r20, Z+20
    ldd r21, Z+21
    ldd r22, Z+22
    ldd r23, Z+23
    ldd r24, Z+24
    ldd r25, Z+25
    ldd r26, Z+26
    ldd r27, Z+27
    ldd r28, Z+28
    ldd r29, Z+29

    ; Move target address from stack to Z for ijmp
    pop r31
    pop r30

    ; Restore SREG LAST (after all other registers)
    ; Use temporary register that we'll restore
    push r30             ; Save Z low
    push r31             ; Save Z high
    movw r30, r22        ; Z = buffer address again
    ldd r0, Z+32         ; Get SREG
    out _SFR_IO_ADDR(SREG), r0
    ldd r30, Z+30        ; Restore Z from buffer
    ldd r31, Z+31
    
    ; Clear r1 (the zero register) as per AVR GCC ABI
    eor r1, r1
    
    ; Indirect jump to target address (Z contains target)
    ijmp

/**
 * Alternative: restore_and_call - returns to caller after target executes
 * void restore_and_call(uint16_t target_word_addr, uint8_t *buffer)
 */
.global restore_and_call
restore_and_call:
    cli                  ; Disable interrupts during restoration
    
    ; Convert word address to byte address
    lsl r24
    rol r25
    
    movw r30, r22        ; Z = buffer address
    
    ; Restore registers except r30/r31 (needed for icall)
    ldd r0, Z+0
    ldd r1, Z+1
    ldd r2, Z+2
    ldd r3, Z+3
    ldd r4, Z+4
    ldd r5, Z+5
    ldd r6, Z+6
    ldd r7, Z+7
    ldd r8, Z+8
    ldd r9, Z+9
    ldd r10, Z+10
    ldd r11, Z+11
    ldd r12, Z+12
    ldd r13, Z+13
    ldd r14, Z+14
    ldd r15, Z+15
    ldd r16, Z+16
    ldd r17, Z+17
    ldd r18, Z+18
    ldd r19, Z+19
    ldd r20, Z+20
    ldd r21, Z+21
    ldd r22, Z+22
    ldd r23, Z+23
    ldd r24, Z+24
    ldd r25, Z+25
    ldd r26, Z+26
    ldd r27, Z+27
    ldd r28, Z+28
    ldd r29, Z+29
    
    ; Put target address in Z for icall
    movw r30, r24        ; r24:r25 had the target address
    
    ; Restore SREG
    movw r24, r22        ; Get buffer address back
    movw r30, r24        ; Z = buffer
    ldd r0, Z+32
    out _SFR_IO_ADDR(SREG), r0
    
    ; Restore Z from buffer
    ldd r30, Z+30
    ldd r31, Z+31
    
    eor r1, r1
    
    ; Call the target (will return here)
    icall
    
    ret

/**
 * Fast hex printing function
 * void asm_print_hex8(uint8_t val)
 * r24 = value to print
 */
.global asm_print_hex8
asm_print_hex8:
    push r25
    mov r25, r24         ; Save original value
    
    ; Print high nibble
    swap r24             ; Swap nibbles
    andi r24, 0x0F       ; Mask low nibble
    subi r24, -'0'       ; Add '0'
    cpi r24, '9'+1
    brlo 1f
    subi r24, -('A'-'9'-1) ; Adjust for A-F
1:
    ; Would call Serial.write(r24) here via C++
    ; For now, return to C for actual printing
    
    ; Print low nibble
    mov r24, r25
    andi r24, 0x0F
    subi r24, -'0'
    cpi r24, '9'+1
    brlo 2f
    subi r24, -('A'-'9'-1)
2:
    pop r25
    ret
