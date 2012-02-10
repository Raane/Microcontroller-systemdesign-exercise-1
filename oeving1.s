/******************************************************************************
 *	
 * Øving 1 UCSysDes
 *	
 *****************************************************************************/

.include "io.s"  /* inkludere noen nyttige symboler (konstanter) */

/* Eksempel på hvordan sette symboler (se også io.s) */
SR_GM =   16  /* statusregisterflag "GM" er bit 16 */
	
/*****************************************************************************/
/* text-segment */
/* all programkoden må plasseres i dette segmentet */
	
.text
	
.globl  _start
_start: /* programutføring vil starte her */

    /* Setting up various constants for easy access later */
    /* r0:  PIO B (BUTTONS) */
    /* r1:  PIO C (LEDS)    */
    /* r13: INTC    */
    lddpc r0, piob_pointer /*saving PIO constants for later use */
    lddpc r1, pioc_pointer
    lddpc r13, intc_pointer 
    mov r2, 0xff /* 11111111 used to initialize the diodes*/
    mov r3, 0x00 /* 00000000 used on various occasions */
    mov r4, 0b00000001 /* constant to set initial LED  */
    mov r10, 0b10000000
    mov r11, 0b00100000
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
    st.w r13[AVR32_INTC_IPR14], r7               /* using the interrupt routine
                                                    address as the autovector;
                                                    we can do tis because EVBA
                                                    is at address 0 */
    csrf 16 /* setting the Global Interrupt Mask (GM) to 

    /* initializing state */
    st.w r1[AVR32_PIO_SODR],  r4 /* turn on initial LED */

/* Main loop. Hang out here when nothing else is happening. */
loop:
    sleep 1
    rjmp loop

rol:
        cp.w r4, r10
        breq rol_end
        lsl r4, 1
        rjmp set_leds

rol_end:
        mov r4, r12
        rjmp set_leds
ror:
        cp.w r4, r12
        breq ror_end
        lsr r4, 1
        rjmp set_leds

ror_end:
        mov r4, r10
        rjmp set_leds

set_leds:
        st.w r1[AVR32_PIO_CODR], r2
        st.w r1[AVR32_PIO_SODR], r4
        rjmp button_interrupt_return

check_buttons:   /* evig løkke */
        mov r9, r5
        ld.w r5,r0[AVR32_PIO_PDSR] /* get status of buttons in r5 */
        com r5
        mov r6, r5
        and r5, r10
        cp.w r5, r10
        breq rol
        and r6, r11
        cp.w r6, r11
        breq ror

/* Introducing some delay to combat bouncing */
debounce:
    mov r5, 0xffff
    debounce_loop:
        sub r5, 1
        cp r5, 0
        brne debounce_loop
    rete

button_interrupt:
        ld.w r8, r0[AVR32_PIO_ISR]  /* loading from ISR to notify that
                                        the interruption is being handled */
        st.w --sp, r5
        ld.w r5, r0[AVR32_PIO_PDSR]
        cp.w r5, r7
        mov r7, r5
        ld.w r5, sp++
        brne check_buttons
    button_interrupt_return:
        call debounce
        rete


piob_pointer: 
        .int AVR32_PIOB /* loads the adress of PIOB to a variable */
pioc_pointer: 
        .int AVR32_PIOC /* loads the adress of PIOC to a variable */
intc_pointer: 
        .int AVR32_INTC /* loads the adress of INTC to a variable */

/*****************************************************************************/
/* data-segment */
/* alle dataområder som skal kunne skrives til må plasseres her */
	
.data
	
