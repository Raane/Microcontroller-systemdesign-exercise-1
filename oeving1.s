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
    mov r2, 0xff /* 11111111 used to initialize the diodes*/
    mov r3, 0x00 /* 00000000 used on various occasions */
    mov r10, 0b10000000
    mov r11, 0b00100000
    mov r12, 0b00000001

    lddpc r0, piob_pointer /*saving constants to PIO for later use */
    lddpc r1, pioc_pointer
    st.w r1[AVR32_PIO_PER], r2 /* enable IO pins for LED */
    st.w r1[AVR32_PIO_OER], r2 /* set IO pins to be output for LED */
    st.w r0[AVR32_PIO_PER], r2 /* enable IO pins for BUTTON */
    st.w r0[AVR32_PIO_PUER], r2 /* set IO pins to be input for BUTTON */

    mov r4, 0b00000010 /* constant to set initial LED  */
    st.w r1[AVR32_PIO_SODR],  r4 /* turn on initial LED */

check_buttons:   /* evig løkke */
        mov r9, r5
        ld.w r5,r0[AVR32_PIO_PDSR] /* get status of buttons in r5 */
        com r5 /* invert input from r5*/
        mov r6, r5 /* make a cpoy of r5 */
        and r5, r10 /* check if button 7 is pressed */
        cp.w r5, r10
        breq rol /* jump to rol if is was pressed */
        and r6, r11 /* check if button 5 is pressed */
        cp.w r6, r11
        breq ror /* jump to ror if it aws pressed */

wait_for_change: /* the program will be stuck here until the buttons' state change */
        ld.w r5,r0[AVR32_PIO_PDSR] /* get status of buttons in r5 */
        com r5 /* invert r5 */
        cp.w r5, r9 /* compare r5 to r9 */
        brne check_buttons /* escape loop if there was a change */
        rjmp wait_for_change /* restart loop */

set_leds:
        st.w r1[AVR32_PIO_CODR], r2 /* turn off all leds */
        st.w r1[AVR32_PIO_SODR], r4 /* turn on leds accordingly to the state of r4 */
        rjmp wait_for_change /* go to wait_for_change and wait */
        
rol:
        cp.w r4, r10 /* check if the marker is about to fall off the edge */
        breq rol_end /* if it was, go to rol_end */
        lsl r4, 1 /* logic shift left r4 */
        rjmp set_leds /* set leds */

rol_end:
        mov r4, r12 /* set r4 to r12 and set_leds */
        rjmp set_leds
ror:
        cp.w r4, r12 /* check if the marker is about to fall off the edge */
        breq ror_end /* if it was, go to ror_end */
        lsr r4, 1 /* logic shift right r4 */
        rjmp set_leds /* set leds */


ror_end:
        mov r4, r10 /* set r4 to r10 and set_leds */
        rjmp set_leds

piob_pointer: 
        .int AVR32_PIOB /* loads the adress of PIOB to a variable */
pioc_pointer: 
        .int AVR32_PIOC /* loads the adress of PIOC to a variable */

/*****************************************************************************/
/* data-segment */
/* alle dataområder som skal kunne skrives til må plasseres her */
	
.data
	
