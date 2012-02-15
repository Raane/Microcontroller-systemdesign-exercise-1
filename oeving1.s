/******************************************************************************
 *	
 * Øving 1 UCSysDes
 *	
 *****************************************************************************/

.include "io.s"  /* inkludere noen nyttige symboler (konstanter) */

SR_GM =   16  /* statusregisterflag "GM" er bit 16 */
	
/*****************************************************************************/
/* text-segment */
	
.text
	
.globl  _start
_start: /* entry point */

    /* Setting up various constants for easy access later */
    /* r0:  PIO B (BUTTONS) */
    /* r1:  PIO C (LEDS)    */
    /* r8:  INTC            */
    lddpc r0, piob_pointer
    lddpc r1, pioc_pointer
    lddpc r8, intc_pointer

    /* IO mask constants */
    mov r2,  0b11111111
    mov r3,  0b00000000 
    mov r4,  0b00001000 /* constant to set initial LED  */
    mov r10, 0b10000000 /* left button mask */
    mov r11, 0b00100000 /* right button mask */
    mov r12, 0b00000001

    /* setting up input and output */
    st.w r1[AVR32_PIO_PER], r2 /* enable IO pins for LED */
    st.w r1[AVR32_PIO_OER], r2 /* set IO pins to be output for LED */
    st.w r0[AVR32_PIO_PER], r2 /* enable IO pins for BUTTON */
    st.w r0[AVR32_PIO_PUER], r2 /* set IO pins to be input for BUTTON */

    /* setting up interrupts for the buttons */
    st.w r0[AVR32_PIO_IER], r2 /* Enabling interrupts for all the buttons */
    mtsr 4, r3 /* We choose 0 to be the address for EVBA, as suggested in 
                  section 2.5.2 of the compendium. */

    mov r7, button_interrupt
    st.w r8[AVR32_INTC_IPR14], r7               /* using the interrupt routine
                                                    address as the autovector;
                                                    we can do tis because EVBA
                                                    is at address 0 */

    csrf SR_GM /* setting the Global Interrupt Mask (GM)

    /* initializing state */
    st.w r1[AVR32_PIO_SODR],  r4 /* turn on initial LED */



/* Main loop. Hang out here when nothing else is happening. */
loop:
    sleep 1 /* Go into sleepstate frozen (wake on internal or external interupt) */
    rjmp loop /* Interupt event over, go back to sleep */



move_paddle_left:
        cp.w r4, r10 /* check if the paddle is about to fall off the left edge */
        breq move_paddle_left_end /* if it is, go to move_paddle_left_end */
        lsl r4, 1 /* move the paddle one to the left */
        rjmp set_leds 
    move_paddle_left_end:
        mov r4, r12 /* move the paddle to the far right */
        rjmp set_leds


move_paddle_right:
        cp.w r4, r12 /* check if the paddle is about to fall off the right edge */
        breq move_paddle_right_end /* if it was, go to move_paddle_right_end */
        lsr r4, 1 /* logic shift right r4 */
        rjmp set_leds /* set leds */
    move_paddle_right_end:
        mov r4, r10 /* set r4 to r10 and set_leds */
        rjmp set_leds

set_leds:
        st.w r1[AVR32_PIO_CODR], r2 /* turn off all leds */
        st.w r1[AVR32_PIO_SODR], r4 /* turn on leds according to the state of r4 */
        rjmp button_interrupt_return /* go to button_interrupt_return */


button_interrupt:
        ld.w r8, r0[AVR32_PIO_ISR]  /* loading from ISR to notify that
                                        the interruption is being handled */
        ld.w r5,r0[AVR32_PIO_PDSR] /* get status of buttons in r5 */
        com r5 /* Invert the buttons */
        mov r6, 0b10100000
        and r5, r6 /* Filters out uninteresting buttons */
        mov r7, r5 /* Backs up buttons for future usage */
        eor r5, r9 /* Detects buttons with changes */
        and r5, r7 /* Filters button releases */
        mov r9,r7 /* backs up the buttonstate for next interupt */
        cp.w r5, r10 /* Checks if SW7 was pressed and jumps if needed */
        breq move_paddle_left
        cp.w r5, r11 /* Checks if SW5 was pressed and jumps if needed */
        breq move_paddle_right

    button_interrupt_return:
        call debounce
        rete /* end the interrupt */

/* Introducing some delay to combat bouncing */
debounce:
        mov r5, 0xffff
        debounce_loop:
            sub r5, 1
            cp r5, 0
        brne debounce_loop
        rete


piob_pointer: 
        .int AVR32_PIOB /* loads the adress of PIOB to a variable */
pioc_pointer: 
        .int AVR32_PIOC /* loads the adress of PIOC to a variable */
intc_pointer: 
        .int AVR32_INTC /* loads the adress of INTC to a variable */
stack_pointer:
	.int _stack



/*****************************************************************************/
/* data-segment */
/* alle dataområder som skal kunne skrives til må plasseres her */
	
.data
	
