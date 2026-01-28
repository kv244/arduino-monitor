#include <avr/io.h>
#include <avr/interrupt.h>

/* Register storage for r0-r31 + SREG */
uint8_t register_snapshot[33];

.section .text

/* 
 * void capture_registers(uint8_t *buffer)
 * Captures r0-r31 and SREG into the provided buffer.
 * buffer must be at least 33 bytes.
 * r24:r25 contains the address of the buffer.
 */
.global capture_registers
capture_registers:
    push r30
    push r31
    
    movw r30, r24    ; Z = buffer address
    
    ; Save r0 - r31
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
    
    ; Pop saved R30/R31 and store them
    pop r0 ; Temp restore R31
    pop r1 ; Temp restore R30
    st Z+, r1 ; Store R30
    st Z+, r0 ; Store R31
    
    ; Store SREG
    in r0, _SFR_IO_ADDR(SREG)
    st Z+, r0
    
    ret

/*
 * void call_address(uint16_t address)
 * Performs an indirect call to the provided flash address.
 * r24:r25 contains the address.
 */
.global execute_at_address
execute_at_address:
    movw r30, r24
    icall
    ret
