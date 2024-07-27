
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

svc_int:

	; Récupère l'argument du SVC

	mrs r0, msp ; répupère l'addr de la stack
	adds r0, #0x18 ; offset de l'adresse de retour.
	ldr.n r0, [r0] ; Récupère l'addr de retour
	subs r0, #2 ; Offset pour atteindre l'argument de l'instruction SVC
	ldrb.n r0, [r0] ; Récupération de cet argument !

	cmp r0, #0
	beq .c0
	
.end:
	ldr.n r0, [.retval]
	bx r0
.c0:
	bl syscall0
	b .end



.text: db "Syscall 0x", 0
.hex: db "00",10,0
align 4
.textaddr: dw .text
.hexaddr: dw .hex
.retval: dw 0xFFFFFFF9