// File:    		arctan.asm
//
// Author:		Kai Ho Chak	
// Date:		Dec 4, 2021
// 
// Description:
//
// An assembly language program to compute the function arctan(x) given a input file
//

// data
			.data
			.balign 8					

zero_m:			.double	0r0.0								// a floating point of 0.0
stop_m:			.double 0r1.0e-13							// the absolute value of the term is less than 1.0e-13.

// text
			.text
			.balign	4

error_arg: 		.string "Please Enter Correct Format of Arguments\nPlease enter as: ./a6 input.bin \n" 
error_open:		.string "could not open %s\n"
error_close:		.string "could not close %s\n"
header_str:		.string "\n|      Value of x      |    Value of arctan(x)   |\n"
pos_str:		.string "|    +%.10f     |"
neg_str:		.string "|    %.10f     |"
pos_arctan_str:		.string "      +%.10f      |\n"
neg_arctan_str:		.string "      %.10f      |\n"  

// equates
		fp	.req 	x29								// equate x29 as frame pointer
		lr	.req	x30								// equate x30 as link register

// definition (callee saved)
		define(argc_r, w19)								// number of arguments passed into main()
		define(argv_r, x20)								// base address of pointers array to the command line
		define(count_r, w21)								// counter for loop
		define(term_r, w22)								// term count for arctan()

// definition (floating point)	
		define(x_r, d15)								// value of x
		define(zero_r, d14)								// a floating point of 0.0
		define(sum_r, d13)								// sum value of arctan(x) 
		define(n_r, d12)								// value of the exponent n of the numerator x^n of 
												// each element x^n/n in arctan(x)
		define(stop_r, d11)								// the absolute value of the term is less than 1.0e-13i
		define(val_r,d10)								// value of each term in arctan(x)
		define(numer_r, d9)								// the numerator x^n in arctan(x)  

// variables	
		fd_size = 4									// handle for the file descriptor 
		val_size = 8 									// each input value is double precision, thus 8 bytes long
		bytes_read_size = 4								// bytes read
		argv_size = 8									// base address of pointers array to the command line
	
		alloc = -(16 + fd_size + val_size + bytes_read_size + argv_size) & -16	

												// allocate space divisible by 16
		dealloc = -alloc								// deallocate space divisible by 16

		fd_o = 16									// offset for file descriptor
		val_o = 20									// offset for input value
		bytes_read_o = 28								// offset for bytesread
		argv_o = 32									// offset for base address pointers to command line argument

// main()
	
		.balign 4									// divisible by 4 as aligned with the word length
		.global main									// make sure the label is picked by the linker

main: 		

		stp     fp, lr, [sp, alloc]!      						// store the FP and LP to stack 
		mov     fp, sp                  						// move the SP to the FP

read_argv:	

		mov 	argc_r, w0								// store number of argument into w0
		mov 	argv_r, x1								// store base address to an array containing the args into x1
		cmp 	argc_r, 2								// make sure only 2 command line arguments
		b.eq	openf									// only proceed when we have 2 command line arguments
		
		adrp	x0, error_arg								// otherwise, copy the address of error_arg 
		add 	x0, x0, :lo12:error_arg							// clear the botom 12 bits to zero
		bl 	printf									// print the error message
		
		mov	x0, -1									// setup return value of -1
		b	exit_main								// exit program

openf:		

		mov	w0, -100								// 1st arg (use cwd): mov AT_FDCWD = -100 into w0, 
												//     to indicate the pathname relative to the program's cwd
		mov	w19, 1									// 2nd arg (pathname): copy the 2nd command line argument 
		ldr	x1, [argv_r, w19, SXTW 3]						//     by accessing the address at [argv + 1 * 8] in stack
		mov	w2, 0									// 3rd arg (read only): set 00 as the flag of O_RDONLY
		mov	w3, 0									// 4th arg (not used): no need for opening a file

		mov	x8, 56									// set x8 = 45 (openat) I/O request
		svc	0									// call system function: openat (-100, filename, 0, 0)		
		str	w0, [fp, fd_o]								// store the handle in stack

		cmp	w0, 0									// error check: -1 is error
		b.ge	init_zero								// if successful, jump to init_zero 
												//	to initialize zero for later use
	
		adrp	x0, error_open								// if unsuccessful, copy the address of error_open
		add 	x0, x0, :lo12:error_open						// 	clear the bottom 12 bits to zero
		mov	w19, 1				
	
		ldr	x1, [argv_r, w19, SXTW 3]						// copy filename
		bl 	printf									// 	print error message
 
		mov	x0, -1									// setup return value of -1	
		b	exit_main								// exit program
		
init_zero:	
		
		adrp	x19, zero_m								// store the address of zero_m into x19 
		add 	x19, x19, :lo12:zero_m							// 	clear the bottom 12 bits to zero
		ldr	zero_r, [x19]								// load 0.0 into zero_r for later uses

readf:		

		adrp	x0, header_str								// store the address of header_str
		add	x0, x0, :lo12:header_str						// 	clear the bottom 12 bits to zero
		bl	printf									// print the header

loop_read:	

		ldr	w0, [fp, fd_o]								// 1st arg (fd): load to w0 the handle of file descriptor 
												// 	set by openat() that was stored in memory
		add	x1, fp, val_o								// 2nd arg (ptr to val): put into x1 the address of where 
												// 	the value will be stored on stack
		mov	x2, 8									// 3rd arg (n): w2 = number of bytes to read (8 bytes) 

		mov	x8, 63									// x8 = 63 (read) I/O request
		svc	0									// call system funnction: read (fd, &value, 8)
		str	w0, [fp, bytes_read_o]							// store the bytes read

		cmp	w0, 8									// check if bytes read = 8
		b.ne	closef									// if not, i.e. EOF, close file
	
		ldr	d0, [fp, val_o]								// otherwise, load value into d0 register 
		
check_sign:	

		fcmp	d0, zero_r								// check the sign of input value
		b.ge	pos_val									// print positive value if >= 0

neg_val:	

		adrp	x0, neg_str								// store the address of neg_str
		add	x0, x0, :lo12: neg_str							// 	clear the bottom 12 bits to zero
		bl	printf									// print value of x
		
		b	print_arctan								// go to print_arctan

pos_val:	

		adrp	x0, pos_str								// store the address of pos_str
		add	x0, x0, :lo12: pos_str							// 	clear the bottom 12 bits to zero
		bl 	printf									// print value of x

print_arctan:	

		ldr	d0, [fp, val_o]								// load value into d0 
		bl	arctan									// call arctan(x)

check_arctan:   

		fcmp    d0, zero_r           							// check the sign of return value of arctan()
        	b.ge    pos_arctan      							// print positive value if >= 0

neg_arctan:     

		adrp    x0, neg_arctan_str                  					// store the address of neg_arctan_str
        	add     x0, x0, :lo12: neg_arctan_str       					// 	clear the bottom 12 bits to zero
        	bl      printf                          				  	// print value of arctan()

        	b       loop_read                           				   	// go to call_arctan 

pos_arctan:     

		adrp    x0, pos_arctan_str                    					// store the address of pos_arctan_str
        	add     x0, x0, :lo12: pos_arctan_str        				   	// 	clear the bottom 12 bits to zero
        	bl      printf                               				   	// print value of arctan()

       		b       loop_read                           				    	// go back to loop_read to read another input value

closef:		

		ldr	w0, [fp, fd_o]								// 1st arg (fd)
		mov	x8, 57									// close I/O request
		svc	0									// call system function

		cmp	w0, 0									// error check
		b.ge	exit_main								// if successful, jump to exit_main
				
		ldr	x0, =error_close							// if unsuccessful, print error message
		mov	w19, 1
		ldr	x1, [argv_r, w19, SXTW 3]						// copy filename
		bl	printf

		mov	x0, -1									// setup return value of -1
		b	exit_main								// exit program

exit_main:	
		ldp     fp, lr, [sp], dealloc       						// restore sp to fp and lr then do sp +16 and set to sp
        	ret                             						// return to the OS

// arctan()
		.balign 4									// divisible by 4 as aligned with the word length
		.global arctan									// make sure the label is picked by the linker

arctan:		

		stp	fp, lr, [sp, -16]!							// store the FP and LP to stack 
        	mov     fp, sp                                 					 // move the SP to the FP
		
		fmov	x_r, d0									// store passed value x into x_r		

		fmov	n_r, 1.0								// initialize n = 1.0 			
		fmov	d16, 2.0								// initialize d16 = 2.0, for incrementing n later
		
		mov	term_r, 1								// initialize term = 1 	
		fmov	sum_r, zero_r								// initialize sum = 0
		
		adrp	x9, stop_m								// store the address of stop_m
		add	x9, x9, :lo12:stop_m							// 	clear the bottom 12 bits to zero
		ldr	stop_r, [x9]								// load stop_m into stop_r

loop_arctan:	

		cmp	term_r, 1								// check if it is the 1st term  	
		b.ne	not_first								// 	if not 1st term, jump to not_first	

base:		

		fmov	val_r, x_r								// otherwise store val = x
		fmov	numer_r, x_r								// store the numerator  x^{n} = x for later use
		b	add_arctan								// jump to add_arctan	

not_first:	

		fmul	numer_r, numer_r, x_r							// update numerator: x^{n+1} = x^n * x (increase one exponent)
		fmul	numer_r, numer_r, x_r							// 	x^{n+2} = x^{n+1} * x (increase one more exponent)
		fneg	numer_r, numer_r							// 	flip sign +/- for each term
												// 		for odd # term: + x^{n+2}
												// 		for even # term: - x^{n+2}	
		fdiv	val_r, numer_r, n_r							// leave numerator as it is 
												// 	but update value of the element:
												//		val = +- x^{n+2} / n	

check_abs:	

		fabs	d16, val_r								// take the absolute value of the term
		fcmp	d16, stop_r								// check absolute value of the term is less than 1.0e-13
		b.lt	exit_arctan								// 	if less than, exit arctan()
	
add_arctan:	

		fadd	sum_r, sum_r, val_r							// otherwise, add value of term to the total sum of arctan(x)
		
		add	term_r, term_r, 1							// increment term count by 1	
		fadd	n_r, n_r, d16								// increment n by 2.0
		b	loop_arctan								// back to loop_arctan, for computing the next term	
	
exit_arctan:	fmov	d0, sum_r 								// return value of arctan(x)
		ldp	fp, lr, [sp], 16
		ret
