// Title:		Polynomial Equations 
// 
// Author:		Kai Ho Chak	
// Date:		Sept 28, 2021
// 
// Description: 
// 
// An A64 program that finds the maximum of y = -3x^4 + 267x^2 + 47x - 43 in the range -10 <= x <= 10
// by stepping through the range one by one in a loop and testing.
//

x_string: 	.string "current x value: %d\n"		
y_string:	.string "current y value: %d\n"		 
max_string:	.string "current max value: %d\n\n"	

		.balign 4					// align with the word length of the machine

		.global main					// ensure main label is picked by the linker

main:	

		stp	x29, x30, [sp, -16]! 			// store the FP and LP to stack in stack 
								// with two double space 
		mov 	x29, sp					// move SP to the FP

		mov 	x19, -10				// set x19(value of x) to value -10
		mov 	x20, 0					// set x20(temp) to value 0
		mov	x21, 0					// set x21(sum) to value 0
		mov 	x22, 47					// set x22(degree-1 coefficient) to value 47
		mov	x23, 267				// set x23(degree-2 coefficient) to value 267
		mov	x24, -3					// set x24(degree-4 coefficient) to value -3
		mov 	x25, 0					// set x25(max value) to value 0
	
while_loop:	

		cmp 	x19, 10					// compare x19(value of x) with 10
		b.gt	exit					// if (x19 > 10) -> exit

		mov 	x21, 0 					// reset x21(sum) to value 0
		add     x21, x21, -43				// add constant to sum

		mul 	x20, x22, x19				// value of degree-1 term  
		add     x21, x21, x20				// add value of degree-1 term to sum

		mul 	x20, x19, x19				// square the value of x  
		mul 	x20, x23, x20				// value of degree-2 term
		add     x21, x21, x20				// add value of degree-2 term to sum

		mul	x20, x19, x19				// square the value of x
		mul     x20, x20, x19				// cube the value of x
		mul     x20, x20, x19				// get the value of x^4
		mul 	x20, x24, x20				// value of degree-4 term  
		add     x21, x21, x20				// add value of degree-4 term to sum

		adrp	x0, x_string				// point the x0 to x_string
		add 	x0, x0, :lo12:x_string  		// add the first 12 bytes of x_string		
		mov	x1, x19					// print current value of x
		bl	printf					// branch to a label printf
	
		adrp	x0, y_string				// point the x0 to y_string
		add 	x0, x0, :lo12:y_string  		// add the first 12 bytes of y_string		
		mov	x1, x21					// print current value of y
		bl	printf					// branch to a label printf
	
		adrp	x0, max_string				// point the x0 to max_string
		add 	x0, x0, :lo12:max_string  		// add the first 12 bytes of max_string		

		cmp 	x19, -10				// compare x19(value of x) with -10
		b.eq	update_max				// if (x19 == -10) -> update_max

		cmp 	x25, x21				// compare values of max and sum
		b.le	update_max				// if (x25 < x21) -> update_max 

		mov 	x1, x25					// print current max value
		bl	printf					// branch to a label printf
	
		add	x19, x19, 1 				// increment x19 by 1
		b	while_loop				// repeat the loop

update_max:	

		mov	x25, x21				// update maximum value
		mov	x1, x25					// print current max value
		bl	printf					// branch to a label printf
		
		add	x19, x19, 1 				// increment x19 by 1
		b 	while_loop 				// branch back to while_loop

exit:	
		ldp 	x29, x30, [sp], 16			// restore sp to x29 and x30 then do sp + 16
								// and set to sp 
		ret						// return to the OS 	
