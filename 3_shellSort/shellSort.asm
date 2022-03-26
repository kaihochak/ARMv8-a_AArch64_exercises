// Title:    	shellSort.asm
//
// Author:		Kai Ho Chak	
// Date:		Oct 18, 2021
//   
// Description: 
// 
// This program create an array and display it. It is then followed by an algorithm
// that sort the array into descending order using a shell sort. It displays the 
// sorted array before ending. 

fp .req x29   							// rename x29 to FP
lr .req x30								// rename x30 to LR

array_size = 100						// number of array elements
v_size = array_size * 4					// size of array V[100]
gap_size = 4							// size of gap
i_size = 4								// size of i
j_size = 4								// size of j
temp_size = 4							// size of temp

// for allocate and deallocate frame record on stack

define(alloc, -(16 + v_size + gap_size + i_size + j_size + temp_size) & -16)
dealloc = -alloc

// reference to FP for each variables 

v_s = 16
gap_s = 16 + v_size
i_s = 16 + v_size + gap_size
j_s = 16 + v_size + gap_size + i_s
temp_s = 16 + v_size + gap_size + i_s + j_s

define(v_base_r, x19)					// array base address 
define(gap_r, w20)						// for gap
define(i_r, w21)						// for i
define(j_r, w22)						// for j
define(temp_r, w23)						// for temp

unsort_str: 	.string "Unsorted array:\n"
output_str: 	.string "\nSorted array:\n"		 
array_str:		.string "v[%d] = %d\n"
		
		.balign 4						// align with the word length of the machine
		.global main					// ensure main label is picked by the linker

main:

		stp     fp, lr, [sp, alloc]!	// store frame record to stack store array of 100
										// ensure divisible by 16
		mov     fp, sp      	  		// move SP to the FP


		add		v_base_r, fp, v_s		// calculate array base address
		mov 	i_r, wzr				// initialize counter to 0
		str		i_r, [fp, i_s]			// store value of i_r on stack		

rand_loop:

		ldr 	i_r, [fp, i_s]			// laod value to i_r from stack	
		cmp		i_r, array_size			// compare until the end of array
		b.ge	end_rand_loop			// display if more than 100	
	
		bl		rand					// get a random integer otherwise
		mov		w25, w0					// store the random integer output
		and 	w25, w25, 0x1FF 		// mod 512

		str 	w25, [v_base_r, i_r, sxtw 2]	// store value on stack

		add 	i_r, i_r, 1				// update counter
		str		i_r, [fp, i_s]			// store value of i_r on stack:		
		
		b		rand_loop				// loop again		

end_rand_loop:

		ldr 	x0, =unsort_str			// print heading
		bl		printf
		
		mov		i_r, wzr				// reset i_r
		str		i_r, [fp, i_s]			// store value of i_r on stack

print_unsort:	
	
		ldr		i_r, [fp, i_s]			// load value to i_r from stack	
		cmp		i_r, array_size			// compare until the end of array
		b.ge	end_print_unsort		// sort if more than 100
	
		// display sorted array

		ldr 	x0, =array_str		 			
		mov		w1, i_r						// index number
		ldr 	w2, [v_base_r, i_r, SXTW 2]	// store value on stack
		bl 		printf

		add 	i_r, i_r, 1				// update counter
		str 	i_r, [fp, i_s]			// store value of i_r on stack
		b		print_unsort			// loop again		

end_print_unsort:

		mov 	w25, array_size 		// SIZE
		lsr		gap_r, w25, 1			// initialize gap = SIZE/2
		str		gap_r, [fp, gap_s]		// store value of gap_r to stack	

sort_array:
		
		/* Sort the array into descending order using a shell sort */

		ldr		gap_r, [fp, gap_s]		// load from stack
		cmp		gap_r, wzr				// compare gap > 0
		b.le	end_sort				// end sorting if gap <= 0

		// initialize for mid loop
		mov 	i_r, gap_r				// initialize i = gap
		str 	i_r, [fp, i_s]			// store to stack

mid_sort_loop:
	
		ldr		i_r, [fp, i_s]			// load from stack
		cmp		i_r, array_size			// compare i < SIZE
		b.ge	end_mid_sort			// end mid_loop if i >= SIZE

		// initialize for inner loop
		sub		j_r, i_r, gap_r			// initialize j = i - gap
		str		j_r, [fp, j_s]			// store to stack		

inner_sort_loop:

		ldr 	j_r, [fp, j_s]			// load from stack	
		cmp		j_r, 0					// check if j >= 0
		b.lt	end_inner_sort			// end inner_loop if j < 0

		ldr		w25, [v_base_r, j_r, SXTW 2] 	// load v[j]
		add		w26, j_r, gap_r					// j+gap
		ldr 	w27, [v_base_r, w26, SXTW 2] 	// load v[j+gap]
		cmp 	w25, w27						// compare v[j] < v[ j+gap ]
		b.ge	end_inner_sort					// end inner_loop if v[j] >= v[j+gap]	
			
		/* exchange out of order items */
		mov		temp_r, w25						// temp = v[j]	
		str		temp_r, [fp, temp_s]			// store temp_r to stack
	
		mov		w25, w27						// v[j] = v[j+gap]
		str		w25, [v_base_r, j_r, SXTW 2]	// store to stack			

		ldr		temp_r, [fp, temp_s]			// load temp_r from stack
		mov		w27, temp_r						// v[j+gap] = temp
		str 	w27, [v_base_r, w26, SXTW 2]	// store to stack

		sub		j_r, j_r, gap_r					// updating j_r by j - gap
		str 	j_r, [fp, j_s]					// store to stack
		bl		inner_sort_loop

end_inner_sort:

		add 	i_r, i_r, 1						// update i_r by adding 1
		str		i_r, [fp, i_s]					// store to stack

		b		mid_sort_loop

end_mid_sort:
		
		lsr		gap_r, gap_r, 1					// update: divide gap by 2
		str		gap_r, [fp, gap_s]				// store value of gap_r to stack

		b		sort_array		

end_sort:

		ldr 	x0, =output_str		
		bl 		printf

		mov		i_r, wzr						// reset i_r
		str		i_r, [fp, i_s]					// store value of i_r on stack

print_sort:

		ldr		i_r, [fp, i_s]
		cmp		i_r, array_size					// compare until the end of array
		b.ge	exit
	
		// display sorted array
		ldr 	x0, =array_str		 			
		mov		w1, i_r							// index number
		ldr 	w2, [v_base_r, i_r, SXTW 2]		// store value on stack
		bl 		printf

		add 	i_r, i_r, 1						// update counte
		str		i_r, [fp, i_s]					// store from i_r to stack
		b		print_sort						// loop again		

exit:

		ldp		fp, lr, [sp], dealloc			// restore frame record  
		ret										// return to the OS


