none_int:
	ldr.n r0, [.retval]
	bx r0
align 4
	.retval: dw 0xFFFFFFF9

systick_interrupt:
	ldr.n r0, [.counterAddr]
	ldr.n r1, [r0]
	adds r1, r1, #1
	str.n r1, [r0]
	ldr.n r0, [.retval]
	bx r0

align 4
	.counter: dw 0
	.counterAddr: dw .counter
	.retval: dw 0xFFFFFFF9
	