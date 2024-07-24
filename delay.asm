; Delay, s'occupe de faire un delay.

delay:
		push.n {r0, r1}
		MOVS R0, #0
		LDR.N R1, [delayValue]
delayLoop:
		ADDS R0, R0, #1
		CMP R0, R1
		BNE delayLoop
		pop.n {r0, r1}
		BX lr

delaybig:
		push.n {r0, r1}
		MOVS R0, #0
		LDR.N R1, [delayValuebig]
delayLoopbig:
		ADDS R0, R0, #1
		CMP R0, R1
		BNE delayLoopbig
		pop.n {r0, r1}
		BX lr

delayOneSec:
	push.n {r0, r1, r2}
	ldr.n r0, [.counterAddr]
	ldr.n r1, [r0]
	ldr.n r2, [.delayValue]
	adds r1, r1, r2
.wait:
	ldr.n r2, [r0]
	cmp r2, r1
	bne .wait
	pop.n {r0, r1, r2}
	bx lr

	align 4
	.counterAddr: dw systick_interrupt.counter
	.delayValue: dw 1000000

delay100us:
	push.n {r0, r1, r2}
	ldr.n r0, [.counterAddr]
	ldr.n r1, [r0]
	ldr.n r2, [.delayValue]
	adds r1, r1, r2
.wait:
	ldr.n r2, [r0]
	cmp r2, r1
	bne .wait
	pop.n {r0, r1, r2}
	bx lr

	align 4
	.counterAddr: dw systick_interrupt.counter
	.delayValue: dw 100
