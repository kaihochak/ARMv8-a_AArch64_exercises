// Title:    	Bit Reversal
// 
// Author:	Kai Ho Chak	
// Date:	Oct 5, 2021
// 
// Description: 
// 
// Bit Reversal using Shift and Bitwise Logical Operations

/* Use 32-bit registers for variables declared using int */

define(x_r, w19)
define(y_r, w20)
define(t1_r, w21)
define(t2_r, w22)
define(t3_r, w23)
define(t4_r, w24)
define(temp_r, w25)

format_str: 	.string "original: 0x%08X    reversed: 0x%08X\n"		 

		.balign 4						// align with the word length of the machine

		.global main						// ensure main label is picked by the linker

main:

		stp     x29, x30, [sp, -16]! 	 			// store the FP and LP to stack in stack 
                                   					// with two double space 
		mov     x29, sp        					// move SP to the FP

		ldr	x0, =format_str
		mov	x_r, 0x01FF01FF					// initalize variable x_r

		/* Reverse bits in the variable */

		/* step 1 */

		and 	temp_r, x_r, 0x55555555  			// (x & 0x55555555) 
		lsl	t1_r, temp_r, 1					// t1 = (x & 0x55555555) << 1
		lsr 	temp_r, x_r, 1					// (x >> 1)		
		and 	t2_r, temp_r, 0x55555555			// t2 = (x >> 1) & 0x55555555
		orr 	y_r, t1_r, t2_r 				// y = t1 | t2	

		/* step 2 */

		and 	temp_r, y_r, 0x33333333				// (y & 0x33333333)		
		lsl 	t1_r, temp_r, 2					// t1 = (y & 0x33333333) << 2
		lsr	temp_r, y_r, 2					// (y >> 2)
		and 	t2_r, temp_r, 0x33333333			// t2 = (y >> 2) & 0x33333333
		orr	y_r, t1_r, t2_r					// y = t1 | t2

		/* step 3 */

		and 	temp_r, y_r, 0x0F0F0F0F				// (y & 0x0F0F0F0F)
		lsl 	t1_r, temp_r, 4					// t1 = (y & 0x0F0F0F0F) << 4;
		lsr	temp_r, y_r, 4					// (y >> 4)   
		and	t2_r, temp_r, 0x0F0F0F0F			// t2 = (y >> 4) & 0x0F0F0F0F
		orr	y_r, t1_r, t2_r					// y = t1 | t2

		/* step 4 */	

		lsl	t1_r, y_r, 24					// t1 = y << 24;
  		and	temp_r, y_r, 0xFF00				// (y & 0xFF00)
		lsl	t2_r, temp_r, 8					// t2 = (y & 0xFF00) << 8
		lsr	temp_r, y_r, 8					// (y >> 8)
		and	t3_r, temp_r, 0xFF00				// t3 = (y >> 8) & 0xFF00
  		lsr	t4_r, y_r, 24					// t4 = y >> 24
		orr 	temp_r, t1_r, t2_r				// (t1 | t2)
		orr 	temp_r, temp_r, t3_r				// (t1 | t2 | t3)  		
		orr	y_r, temp_r, t4_r 				// y = t1 | t2 | t3 | t4

		/*  Print out the original and reversed variables */

		adrp 	x0, format_str					// point the x0 to format_str
		add 	x0, x0, :lo12:format_str  			// add the first 12 bytes of format_str
		mov 	w1, x_r						// move original variable to w1
		mov	w2, y_r						// move reversed variable to w2
		bl	printf

exit:

		ldp		x29, x30, [sp], 16			// restore sp to x29 and x30 then do 
									// sp + 16 and set to sp
		ret							// return to the OS

