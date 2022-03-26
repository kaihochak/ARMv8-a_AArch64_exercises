// Title:    	Reverse Polish
//
// Author:	Kai Ho Chak	
// Date:	Nov 23, 2021
// 
// Description:
//
// A assembly code based on some C code functions that emulates a Hewlett-Packard calculators
// that use the reverse Polish form of entry

MAXVAL = 100			 
BUFSIZE = 100
MAXOP = 20

fp	.req 	x29							// equate x29 as frame pointer
lr	.req	x30							// equate x30 as link register

define(sp_r, x19)							// for storing address of sp 
define(base_r, x20)							// for storing address of val[]
define(index_m, w21)							// for storing index of array
define(bufp_r, x22)							// for storing address of bufp
define(buf_r, x23)							// for storing address of buf
define(i_m, w24)							// for storing the value of int i
define(c_m, w25)							// for storing the value of int c

/* Global Variables */
.bss					 
		.global sp						// made available to .c

sp:		.skip	4						// int sp = 0;

		.global val						// made available to .c
val:		skip	MAXVAL * 4					// int val[MAXVAL];

		.global buf						// made available to .c
buf:		.skip	BUFSIZE * 1					// buf[BUFSIZE];

		.global bufp						// made available to .c
bufp:		.skip	4						// int bufp;

/* String Literals */
.text					
pop_str:	.string "error: stack empty\n"
push_str:	.string	"error: stack full\n"
ungetch_str:	.string "ungetch: too many characters\n"
test_str: 	.string "testing\n"


/* void clear() */          


                .balign 4               				// divisible by 4 as aligned with the word length
                .global clear           				// make sure the label is picked by the linker
clear:                                                 
        stp     fp, lr, [sp, -16]!      				// store the FP and LP to stack 
        mov     fp, sp                  				// move the SP to the FP

        adrp    sp_r, sp                				// load the address of sp to x19
        add     sp_r,sp_r, :lo12:sp    					// clear the bottom 12 bits to zero     

        str     wzr, [sp_r]           			  		// sp = 0

        ldp     fp, lr, [sp], 16       					// restore sp to fp and lr then do sp +16 and set to sp
        ret                             				// return to the OS


/* int pop() */  
 
 
	        .balign 4                       			// divisible by 4 as aligned with the word length 
        	.global pop                     			// make sure the label is picked by the linker 

pop:    

        stp     fp, lr, [sp, -16]!      				// store the FP and LP to stack  
    	mov     fp, sp                 					// move the SP to the FP 
 
	// I have tried to use sp_r (x19) instead of x20 but it doesn't work. //
	// 	Any reason? Because it's used in clear() already?         // 

    	adrp    x20, sp                					// load the address of sp to x19 
    	add     x20, x20, :lo12:sp    					// clear the bottom 12 bits to zero      

        ldr     w21, [x20]     						// load sp to w21 from stack             
    	cmp     w21, 0         						// if ( sp > 0 ) 
   		b.le    pop_error               			/ print error message if sp <= 0         
    
    	sub    	index_m, w21, 1         				// index -= sp 
    	
		str     index_m, [x20]	        			// store index to sp in stack 
                 
    	adrp   	base_r, val  	              				// load the base address of val to x20 
    	add     base_r, base_r, :lo12:val     				// clear the bottom 12 bits to zero      

    	ldr     w0, [base_r, index_m, SXTW 2] 				// load address of val + offset to w0 
            	                              				// offest: sign extend then index * element size)  

    	b       pop_exit

pop_error: 

    	ldr     x0, =pop_str          					// print error message
    	bl      printf 
         
    	bl      clear							// go to clear()
    	mov     w0, 0							// return 0 

pop_exit:  

    	ldp     fp, lr, [sp], 16       					// restore sp to fp and lr then do sp +16 and set to sp 
    	ret                            					// return to the OS


/* int push(int f) */


	.balign 4								// divisible by 4 as aligned with the word length
	.global push							// make sure the label is picked by the linker

push:

	stp	fp, lr, [sp, -32]!					// store the FP and LP to stack 
												// -(16 + 4) & -16 = -32
	mov	fp, sp							// move the SP to the FP

	str	w0, [sp, 16]						// store int f to stack		

	adrp 	x19, sp  						// load the address of sp to x19
	add	x19, x19, :lo12:sp					// clear the bottom 12 bits to zero	

	ldr	w21, [x19]		
	cmp	w21, MAXVAL						// if ( sp < MAXVAL )
	b.ge	push_error						// print error message if sp >= MAXVAL	 

	adrp 	base_r, val  						// load the base address of val to x20
	add	base_r, base_r, :lo12:val				// clear the bottom 12 bits to zero	

	ldr 	w0, [sp, 16]						// load int f to w0 from stack
	str	w0, [base_r, index_m, SXTW 2]				// load address of val + offset 
									// offest: sign extend then index * element size) 
	
	ldr	w21, [x19]						// load sp to w21				
	add	index_m, w21, 1						// index += sp
	str	index_m, [x19]						// store index to sp in stack

	b 	push_exit	

push_error:

	ldr	x0, =push_str						// print error messag
	bl	printf

	bl	clear							// go to clear()
	mov	w0, 0							// return 0

push_exit:

	ldp	fp, lr, [sp], 32					// restore sp to fp and lr then do sp +16 and set to sp
	ret								// return to the OS


/* int getch() */ 	


	.balign 4							// divisible by 4 as aligned with the word length
	.global getch							// make sure the label is picked by the linker

getch:	

	stp	fp, lr, [sp, -16]!					// store the FP and LP to stack 
	mov	fp, sp							// move the SP to the FP

	adrp 	bufp_r, bufp  						// load the address of bufp to x22
	add	bufp_r, bufp_r, :lo12:bufp				// clear the bottom 12 bits to zero		
	ldr	w24, [bufp_r]		
	cmp	w24, 0							// if ( bufp > 0 )
	b.le	get_char						// getChar() if bufp <= 0	 

	ldr	index_m, [bufp_r]					// w21 = bufp 
	sub	index_m, index_m, 1					// --w21
	str	index_m, [bufp_r]					// bufp = w21
	
	adrp 	buf_r, buf  						// load the base address of buf to x23
	add	buf_r, buf_r, :lo12:buf					// clear the bottom 12 bits to zero	

	ldr	w0, [buf_r, index_m, SXTW 2]				// load address of buf + offset to w0 
									// offest: sign extend then index * element size) 
	
	b 	getch_exit

get_char:

	bl	getchar

getch_exit:

	ldp	fp, lr, [sp], 16					// restore sp to fp and lr then do sp +16 and set to sp
	ret


/* void ungetch(int c) */ 	

	.balign 4							// divisible by 4 as aligned with the word length
	.global ungetch							// make sure the label is picked by the linker

ungetch:	

	stp	fp, lr, [sp, -32]!					// store the FP and LP to stack 
												// -(16 & 4) & -16 = -32
	mov	fp, sp							// move the SP to the FP

	str	w0, [sp, 16]						// store int c to stack from w0  

	adrp 	bufp_r, bufp  						// load the address of bufp to x22
	add	bufp_r, bufp_r, :lo12:bufp				// clear the bottom 12 bits to zero		

	ldr	w19, [bufp_r]		
	cmp	w19, BUFSIZE						// if ( bufp > BUFSIZE )
	b.le	ungetch_addBuf						// put int c into buf[] if bufp <= 0	 

	ldr 	x0, =ungetch_str					// print error message
	bl 	printf 	
	
	b 	ungetch_exit	

ungetch_addBuf:

	ldr	w21, [bufp_r]						// load bufp to w21 from stack	
	add	index_m, w21, 1						// index += bufp 	
	
	ldr 	w0, [sp, 16]						// load int c to w0 from stack 

	adrp 	buf_r, buf  						// load the base address of buf to x23
	add	buf_r, buf_r, :lo12:buf					// clear the bottom 12 bits to zero	

	str	w0, [buf_r, index_m, SXTW 0]				// buf[bufp++] = c 
									// store int c to  address of buf + offset 
									// offest: sign extend then index * element size) 
ungetch_exit:

	ldp	fp, lr, [sp], 32					// restore sp to fp and lr then do sp +16 and set to sp
	ret								// return to the OS

// NOT WORKING!!! USING THE FUNCION IN .C FILE //

/* int getop(char *s, int lim) */ 	


	.balign 4							// divisible by 4 as aligned with the word length
	.global getop1							// make sure the label is picked by the linker

getop1:	

	stp	fp, lr, [sp, -48]!					// store the FP and LP to stack 
												// -(16 + 4 + 4 + 8 + 4) & -16 = -48
	mov	fp, sp							// move the SP to the FP

	str	x0, [sp, 16]						// store char *s from x0 to stack
	str	w1, [sp, 24]						// store int lim from w1 to stack

getop_getch:

	bl 	getch							// c = getch()
	str	w0, [sp, 28]						// store input from getch() to int c in stack
	ldr	c_m, [sp, 28]						// load int c from stack to w25

getop_while:

	// 			Perform this loop			//
	//	 while ((c = getch()) == ' ' || c == '\t' || c == '\n') //

	cmp	c_m, 32							// compare c and ' '
	b.eq	getop_while						// if (c = getch()) == ' '), loop	

	cmp	c_m, 9							// compare c and '\t'
	b.eq	getop_while						// if (c = getch()) == '\t'), loop

	cmp	c_m, 10							// compare c and '\n'
	b.eq	getop_while						// if (c = getch()) == '\n'), loop

getop_if1:	

	cmp	c_m, 48							// compare c and '0'
	b.lt	getop_returnC						// if (c < '0'), return c  
	
	cmp		c_m, 57						// compare c and '9'
	b.gt	getop_returnC						// if (c > '9'), return c

getop_storeS:

	ldr	c_m, [sp, 28]						// load int c from stack to w25
	str	c_m, [sp, 16]						// s[0] = c

	mov	i_m, 1							// i = 1
	str	i_m, [sp, 32]						// store value of int i from w24 to stack
	
	b		getop_for_top

getop_returnC:

	ldr	w0, [sp, 28]						// return c	
	b	getop_exit						// exit

getop_for_top:

	//			Perform this for-loop			//
	// 	for (i = 1; (c = getchar()) >= '0' && c <= '9'; i++)	//
	
	ldr	i_m, [sp, 32]						// load int i to i_m from stack

	bl	getop_getch						// c = getchar()
	ldr	c_m, [sp, 28]						// load int c from stack to w25	

	cmp		c_m, 48						// compare c and '0'
	b.lt	getop_if2						// if (c = getchar()) < '0'), go next if-statement 

	cmp		c_m, 57						// compare c and '9'		
	b.gt	getop_if2						// if ( (c = getchar()) > '9'), go next if-statement

	ldr 	w19, [sp, 24]						// load int lim from stack to w19
	cmp		i_m, w19							// if (i < lim)
	b.ge	getop_for_end						// if not, skip to end of for-loop

	ldr	i_m, [sp, 32]						// load int i from stack to w24
	ldr	c_m, [sp, 28]						// load int c from stack to w25
	ldr	x19, [sp, 16]						// load char *s from stack to x19

	str	c_m, [x19, i_m, SXTW 0]					// s[i] = c; since each char is just one byte
									// adding value of int i to the address of char *s will do	

getop_for_end:

	add	i_m, i_m, 1						// i++
	str	i_m, [sp, 32]						// store value of int i from w24 to stack
	b	getop_for_top						// loop again

getop_if2:

	ldr	w19, [sp, 24]						// load int lim from stack to w19
	ldr	i_m, [sp, 32]						// load int i from stack to w24
	cmp	i_m, w19						// if (i < lim)
	b.ge	getop_else						// if not, go to else		
		
	mov 	w0, c_m							// ungetch(c)
	bl	ungetch							// go to ungetch
	
	ldr	x19, [sp, 16] 						// load char *s from stack to x19
	str	wzr, [x19, i_m, SXTW]					// s[i] = '\0'
	mov	w0, 48							// return NUMBER (NUMBER is '0')

	b	getop_exit 

getop_else:

	//	Perform this while loop				
	// 	while (c != '\n' && c != EOF)		

	ldr	c_m, [sp, 28] 						// load int c from stack to w25
		
	cmp     c_m, 10                			 		// compare c and '\n'
        b.eq    getop_end_while						// if (c == '\n'), end loop 

	cmp	c_m, wzr						// compare c and EOF 
	b.eq	getop_end_while						// if (c == EOF), end loop

	bl	getop_getch						// c = getchar()	
	
	b	getop_else 						// loop again

getop_end_while:

	ldr	x19, [sp, 16]						// load char *s from stack to x19
	ldr	x20, [sp, 24]						// load int lim from stack to x20
	sub	x20, x20, 1						// lim = lim - 1	

	str	xzr, [x19, x20]						// s[lim - 1] = '\0'

	mov	w0, 57							// return TOOBIG (TOOBIG is '9')	

getop_exit:

	ldp	fp, lr, [sp], 48					// restore sp to fp and lr then do sp +48 and set to sp
	ret								// return to the OS



