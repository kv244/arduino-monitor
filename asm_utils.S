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
/*
 * void restore_and_execute(uint16_t target, uint8_t *buffer)
 * Restores r0-r31 and SREG from buffer, then jumps to target.
 * r24:r25 = target address (word)
 * r22:r23 = buffer address
 */
.global restore_and_execute
restore_and_execute:
    movw r30, r22    ; Z = buffer address
    
    ; We can't use Z to jump after we restore r30/31.
    ; Solution: Push target address onto stack and use 'ret' to jump.
    push r24 ; Target Low
    push r25 ; Target High (Note: AVR stack is big-endian for return addresses? No, PC is stored differently)
    ; Actually, for AVR, the stack stores the return address (PC) in high-low or low-high depending on the model.
    ; On ATmega328P, PC is 16-bit. Stack stores PCL (low), PCH (high).
    ; So we push PCH then PCL? No, the instruction 'ret' pops PCH then PCL.
    ; Wait, 'ret' pops PC_High then PC_Low. So we push PC_Low then PC_High.
    
    ; Clean up the stack strategy:
    pop r25 ; PC High
    pop r24 ; PC Low (We basically just swapped them to prepare for 'ret')
    push r24 ; PCL
    push r25 ; PCH
    
    ; Now address is on stack.
    
    ; Restore SREG (r0 as temp)
    ldd r0, Z+32
    out _SFR_IO_ADDR(SREG), r0
    
    ; Restore r0-r29
    ld r0, Z+
    ld r1, Z+
    ld r2, Z+
    ld r3, Z+
    ld r4, Z+
    ld r5, Z+
    ld r6, Z+
    ld r7, Z+
    ld r8, Z+
    ld r9, Z+
    ld r10, Z+
    ld r11, Z+
    ld r12, Z+
    ld r13, Z+
    ld r14, Z+
    ld r15, Z+
    ld r16, Z+
    ld r17, Z+
    ld r18, Z+
    ld r19, Z+
    ld r20, Z+
    ld r21, Z+
    ld r22, Z+
    ld r23, Z+
    ld r24, Z+
    ld r25, Z+
    ld r26, Z+
    ld r27, Z+
    ld r28, Z+
    ld r29, Z+
    
    ; Finally restore Z (r30/31)
    ld r30, Z+
    ld r31, Z+
    
    ret ; Jumps to the address we pushed earlier
