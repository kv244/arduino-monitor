#include <avr/io.h>
#include <avr/interrupt.h>

.section .text

/*
 * void capture_registers(uint8_t *buffer)
 * Captures r0–r31 and SREG into the provided buffer.
 * buffer must be at least 33 bytes.
 * r24:r25 contains the address of the buffer.
 */
.global capture_registers
capture_registers:
    movw r30, r24        ; Z = buffer address

    ; Save r0–r29
    st Z+, r0
    st Z+, r1
    st Z+, r2
    st Z+, r3
    st Z+, r4
    st Z+, r5
    st Z+, r6
    st Z+, r7
    st Z+, r8
    st Z+, r9
    st Z+, r10
    st Z+, r11
    st Z+, r12
    st Z+, r13
    st Z+, r14
    st Z+, r15
    st Z+, r16
    st Z+, r17
    st Z+, r18
    st Z+, r19
    st Z+, r20
    st Z+, r21
    st Z+, r22
    st Z+, r23
    st Z+, r24
    st Z+, r25
    st Z+, r26
    st Z+, r27
    st Z+, r28
    st Z+, r29

    ; Save r30 and r31
    mov r0, r30
    mov r1, r31
    st Z+, r0
    st Z+, r1

    ; Save SREG
    in r0, _SFR_IO_ADDR(SREG)
    st Z+, r0

    ret

/*
 * void restore_and_execute(uint16_t target, uint8_t *buffer)
 * Restores r0–r31 and SREG from buffer, then jumps to target.
 * r24:r25 = target address (word)
 * r22:r23 = buffer address
 */
.global restore_and_execute
restore_and_execute:
    movw r30, r22        ; Z = buffer address

    ; Push target address onto stack (low then high)
    push r24             ; PCL
    push r25             ; PCH

    movw r30, r22        ; Z = buffer address

    ; Restore r0–r29 using Z (fixed displacement)
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
    
    ; Restore SREG (use r0 as temp, it's already restored but we can redo it)
    ldd r0, Z+32
    out _SFR_IO_ADDR(SREG), r0
    ; Restore r0 one last time
    ldd r0, Z+0
    
    ; Finally restore Z (r30 and r31)
    ldd r31, Z+31
    ldd r30, Z+30

    ret                  ; Pops target address and jumps