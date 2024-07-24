; Cette fonction lance un programme sur le coeur 1.
; r1 <- Vector table
; r2 <- Stack addr
; r3 <- Code addr

core1_startcode:
	push.n {lr}
	push.n {r0}
	movs r0, #0
	bl cpufifo_send
	sev
	bl cpufifo_send
	sev
	movs r0, #1
	bl cpufifo_send
	sev
	movs r0, r1
	bl cpufifo_send
	sev
	movs r0, r2
	bl cpufifo_send
	sev
	movs r0, r3
	bl cpufifo_send
	sev
	pop.n {r0}
	pop.n {pc}


core1_code:

	CPSID.N iflags_i 

	ldr.n r0, [.gp25]
	ldr.n r1, [.gp25on]
	ldr.n r2, [.gp25off]
.loop:
	bl delayOneSec
	str.n r1, [r0]
	bl delayOneSec
	str.n r2, [r0]
	b .loop
	
	.end:
	b .end

align 4
.gp25: dw  0x400140CC
.gp25on: dw 0x331F
.gp25off: dw 0x321F