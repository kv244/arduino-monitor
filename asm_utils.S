#include <avr/io.h>

.section .text

/**
 * void capture_registers(uint8_t *buffer)
 * r24:r25 = buffer
 */
.global capture_registers
capture_registers:
    movw r30, r24        ; Z = buffer address
    
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
 * void restore_and_execute(uint16_t target, uint8_t *buffer)
 * r24:r25 = target
 * r22:r23 = buffer
 */
.global restore_and_execute
restore_and_execute:
    movw r30, r22        ; Z = buffer address

    ; Push target address onto stack (low then high)
    push r24             ; PCL
    push r25             ; PCH

    ; Restore SREG
    ldd r0, Z+32
    out _SFR_IO_ADDR(SREG), r0

    ; Restore all registers r0-r29
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

    ; Finally restore Z
    ldd r31, Z+31
    ldd r30, Z+30

    ; Clear r1 (the zero register) as per AVR GCC ABI
    eor r1, r1
    ret