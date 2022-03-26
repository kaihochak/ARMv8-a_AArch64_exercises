// File:    	pyramidRelocate.asm
//  
// Author:	Kai Ho Chak	
// Date:	Oct 28, 2021
// 
// Description: 
//
// Convert some C code based on the following steps:
//
// (1) create a coord struct (int x, y)
// (2) create a size struct (int width, length)
// (3) create a pyramid struct (coord center, size base, int height, int volume)
// (4) create a pyramid constructor - newPyramid(int width, int length, int height)
// (5) create a relocate function - void relocate(struct pyramid *p, int deltaX, int deltaY)
// (6) create a expand function - void expand(struct pyramid *p, int factor)
// (7) create a print function - void printPyramid(char *name, struct pyramid *p)
// (8) create a compare function - int equalSize(struct pyramid *p1, struct pyramid *p2)
// (9) create a main function 
//		- declare two pyramids
// 		- initialize both pyramids
//		- print their values
//		- compare their size
//		- expand the smaller one, and relocate them
//		- print their updated values.
// 

FALSE = 0
TRUE = 1

// offset for struct pyramid
pyramid_center_x = 0 								// struct coord center in struct pyramid
pyramid_center_y = 4	
pyramid_base_width = 8								// struct size base in struct pyramid
pyramid_base_length = 12 
pyramid_height = 16									// int height in struct pyramid 
pyramid_volume = 20									// int volume in struct pyramid

	fp .req x29										// equate x29 as frame pointer 
	lr .req x30										// equate x30 as link register

khafre_size = 24 									// coord-8, size-8, height-4, volume-4  
cheops_size = 24
alloc = -(16 + khafre_size + cheops_size) & -16
dealloc = -alloc 
khafre_s = 16										// offset for khafre
cheops_s = 40										// offset for cheops	

printFmt1:	.string "Pyramid "
printFmt2: 	.string "\tCenter = (%d, %d)\n"
printFmt3:	.string "\tBase width = %d  Base length = %d\n"
printFmt4:	.string "\tHeight = %d\n"
printFmt5:	.string "\tVolume = %d\n\n"
printFmt6:	.string "Initial pyramid values:\n"
printFmt7:	.string "\nNew pyramid values:\n"
print_khafre:	.string "khafre\n"
print_cheops:	.string "cheops\n"

	.balign 4										// are divisible by 4 
	.global main									// pseudo op that sets the start label to main

define(p_base_r, x9)								// for storing address of passed pyramid
define(pyramid1_r, x10)								// for storing address of pyramid1
define(pyramid2_r, x11)								// for storing address of pyramid2
define(result_r, w12)			
define(factor_r, w13)
define(deltaX_r, w14)
define(deltaY_r, w15)

p_size = 24			// coord-8, size-8, height-4, volume-4  
struct_alloc = -(16 + p_size) & -16	
struct_dealloc = -struct_alloc
p_s = 16

newPyramid:

	stp		fp, lr, [sp, struct_alloc]!				// allocate frame record on stack
	mov		fp, sp									// set fp

	add		p_base_r, fp, p_s  						// calculate address of p_base 

	// initialize variables and store on to stack

	// for p.center.x and p.center.y
	str		wzr, [p_base_r, pyramid_center_x] 		// p_center_x = 0
	str		wzr, [p_base_r, pyramid_center_y] 		// p_center_y = 0

	// for p.base.width, p.base.length, and p.height
	str		w0, [p_base_r, pyramid_base_width]		// p_base_width = width
	str		w1, [p_base_r, pyramid_base_length]		// p_base_length = length
	str		w2, [p_base_r, pyramid_height] 			// p_height = height
	
	// for p.volume
	// just follow the original code
	ldr		w10, [p_base_r, pyramid_base_width] 	// p_base_width
	ldr		w11, [p_base_r, pyramid_base_length]	// p_base_length
	ldr		w12, [p_base_r, pyramid_height]			// p_height 
	mul		w13, w10, w11							// width * length 
	mul		w13, w13, w12							// width * length * height
	mov 	w14, 3		
	sdiv	w13, w13, w14							// product of three variables / 3
	str 	w13, [p_base_r, pyramid_volume]			// p_volume

	// return struct to caller

	// for p.center.x 
	ldr		w15, [p_base_r, pyramid_center_x]
	str 	x15, [x8, pyramid_center_x]

	// for p.center.y
	ldr		w15, [p_base_r, pyramid_center_y]
	str		x15, [x8, pyramid_center_y]

	// for p.base.width
	ldr		w15, [p_base_r, pyramid_base_width]
	str		x15, [x8, pyramid_base_width]

	// for p.base.length
	ldr		w15, [p_base_r, pyramid_base_length]
	str		x15, [x8, pyramid_base_length]

	// for p.height
	ldr		w15, [p_base_r, pyramid_height]
	str		x15, [x8, pyramid_height]

	// for p.volume
	ldr		w15, [p_base_r, pyramid_volume]
	str		x15, [x8, pyramid_volume]

	ldp		fp, lr, [sp], struct_dealloc		// restore frame record
	ret

relocate:

	stp		fp, lr, [sp, -32]!					// -(16 + 8 + 4 + 4) & -16 = -32
	mov		fp, sp	
	
	str		x8, [sp, 16]						// store passed struct's address on the stack
	str 	w0, [sp, 16+8]						// store passed int deltaX on the stack
	str		w1, [sp, 16+8+4]					// store passed int deltaY on the stack

	ldr		p_base_r, [sp, 16]					// load back from stack to register
	ldr		deltaX_r, [sp, 16+8]	
	ldr 	deltaY_r, [sp, 16+8+4]

	// p->center.x += deltaX
	ldr 	w11, [p_base_r, pyramid_center_x]
	add		w11, w11, deltaX_r
	str 	w11, [p_base_r, pyramid_center_x]	

	// p->center.y += deltaY
	ldr 	w11, [p_base_r, pyramid_center_y]
	add		w11, w11, deltaY_r
	str 	w11, [p_base_r, pyramid_center_y]	

	// return updated values to caller

	ldr		w11, [p_base_r, pyramid_center_x]
	str		w11, [x8, pyramid_center_x]
	
	ldr		w11, [p_base_r, pyramid_center_y]
	str		w11, [x8, pyramid_center_y]	

	ldp		fp, lr, [sp], 32
	ret

expand:

	stp		fp, lr, [sp, -32]!					// -(16 + 8 + 4) & -16 = -32
	mov		fp, sp								// 8 for struct, 4 for int factor
	
	str		x8, [sp, 16]						// store passed struct's address on the stack
	str 	w0, [sp, 16+8]						// store passed int factor on the stack

	ldr		p_base_r, [sp, 16]					// load back from stack to register
	ldr		factor_r, [sp, 16+8]

	// p->base.width *= factor
	ldr 	w11, [p_base_r, pyramid_base_width]
	mul		w11, w11, factor_r
	str 	w11, [p_base_r, pyramid_base_width]	

	// p->base.length *= factor
	ldr		w11, [p_base_r, pyramid_base_length]
	mul		w11, w11, factor_r
	str		w11, [p_base_r, pyramid_base_length]

	// p->height *= factor
	ldr		w11, [p_base_r, pyramid_height]
	mul		w11, w11, factor_r
	str		w11, [p_base_r, pyramid_height]

	// p->volume = (p->base.width * p->base.length * p->height) / 3
	ldr		w14, [p_base_r, pyramid_base_width]
	ldr		w15, [p_base_r, pyramid_base_length]
	mul		w11, w11, w14
	mul		w11, w11, w15
	mov		w14, 3
	sdiv	w11, w11, w14
	str		w11, [p_base_r, pyramid_volume]	

	// return updated values to caller

	// for p.base.width
	ldr		w15, [p_base_r, pyramid_base_width]
	str		w15, [x8, pyramid_base_width]

	// for p.base.length
	ldr		w15, [p_base_r, pyramid_base_length]
	str		w15, [x8, pyramid_base_length]

	// for p.height
	ldr		w15, [p_base_r, pyramid_height]
	str		w15, [x8, pyramid_height]

	// for p.volume
	ldr		w15, [p_base_r, pyramid_volume]
	str		w15, [x8, pyramid_volume]

	ldp		fp, lr, [sp], 32
	ret

printPyramid:

	stp		fp, lr, [sp, -32]! 					// -(16 + 8) & -16) = -32 
												// an extra 8 bytes for storing x8
	mov		fp, sp

	str		x8, [sp, 16]						// store passed struct's address on the stack

	// print center_x and center_y
	ldr 	x0, =printFmt2
	ldr		x1, [x8, pyramid_center_x]
	ldr		x2, [x8, pyramid_center_y]
	bl 		printf

	// print base_width and base_length
	ldr 	x8, [sp, 16]						// load address back to x8
	ldr		x0, =printFmt3	
	ldr		x1, [x8, pyramid_base_width]
	ldr 	x2, [x8, pyramid_base_length]
	bl		printf	

	// print height
	ldr 	x8, [sp, 16]
	ldr 	x0, =printFmt4
	ldr 	x1, [x8, pyramid_height]
	bl		printf
	
	// print volume
	ldr		x8, [sp, 16]
	ldr		x0, =printFmt5
	ldr		x1, [x8, pyramid_volume]
	bl 		printf
	
	ldp		fp, lr, [sp], 32
	ret

equalSize:

	stp		fp, lr, [sp, -32]!					// -(16 + 16) & -16 = -32
	mov		fp, sp

	str		x0, [sp, 16]						// store passed structs' addresses on stack
	str		x1, [sp, 24]
	ldr		pyramid1_r, [sp, 16]				// load pased structs' addresses 
	ldr 	pyramid2_r, [sp, 24]		

	mov		result_r, FALSE    					// result = FALSE

	// if (p1->base.width == p2->base.width)
	ldr		w13, [pyramid1_r, pyramid_base_width]
	ldr		w14, [pyramid2_r, pyramid_base_width]
	cmp		w13, w14
	b.ne	returnEqual

	// if (p1->base.length == p2->base.length)
	ldr		w13, [pyramid1_r, pyramid_base_length]
	ldr		w14, [pyramid2_r, pyramid_base_length]
	cmp		w13, w14
	b.ne	returnEqual

	// if (p1->base.height == p2->base.height)
	ldr		w13, [pyramid1_r, pyramid_height]
	ldr		w14, [pyramid2_r, pyramid_height]
	cmp		w13, w14
	b.ne	returnEqual

	mov		result_r, TRUE						// result = TRUE

returnEqual:

	ldp		fp, lr, [sp], 32
	ret

main:

	stp		fp, lr, [sp, alloc]!				// allocate frame record on stack
	mov		fp, sp								// set fp

	// khafre = newPyramid(10, 10, 9)
	add		x8, fp, khafre_s					// calculate address of khafre
	mov		w0, 10		
	mov		w1, 10
	mov		w2, 9
	bl		newPyramid
	
	// cheops = newPyramid(15, 15, 18)
	add		x8, fp, cheops_s					// calculate address of cheops
	mov		w0, 15		
	mov		w1, 15
	mov		w2, 18
	bl		newPyramid

	// print initial values
	ldr 	x0, =printFmt6
	bl 		printf

	// passing khafre
	ldr		x0, =printFmt1
	bl		printf
	ldr		x0, =print_khafre	
	bl		printf
	add		x8, fp, khafre_s					// passing .khafre 
	bl		printPyramid			

	// passing cheops
	ldr		x0, =printFmt1
	bl		printf
	ldr		x0, =print_cheops	
	bl		printf
	add		x8, fp, cheops_s					// passing .cheops 
	bl		printPyramid			

	// pass khafre and cheops in equal size	 
	add 	x0, fp, khafre_s
	add		x1, fp, cheops_s
	bl		equalSize

	// if (!equalSize(&khafre, &cheops))
	cmp		result_r, FALSE
	b.ne	printNew
	
	// expand(&cheops, 9)
	add		x8, fp, cheops_s
	mov		w0, 9
	bl		expand

	// relocate(&cheops, 27, -10)	
	add 	x8, fp, cheops_s
	mov		w0, 27
	mov		w1, -10
	bl 		relocate

	// relocate(&khafre, -23, 17)	
	add 	x8, fp, khafre_s
	mov		w0, -23
	mov		w1, 17
	bl 		relocate

printNew:

	ldr	x0, =printFmt7
	bl	printf

	// passing khafre
	ldr		x0, =printFmt1
	bl		printf
	ldr		x0, =print_khafre	
	bl		printf
	add		x8, fp, khafre_s					// passing .khafre 
	bl		printPyramid			

	// passing cheops
	ldr		x0, =printFmt1
	bl		printf
	ldr		x0, =print_cheops	
	bl		printf
	add		x8, fp, cheops_s					// passing .cheops 
	bl		printPyramid		

exit:

	ldp 	fp, lr, [sp], dealloc				// restore frame record
	ret 										// return to the OSi
