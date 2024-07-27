CODE16

; Sortie STDOUT, chaine de caractère null terminated.
;	r4 <- Adresse de la chaine de caractère.

syscall0:
	push.n {lr}
	movs r1, r4
	bl LCD_GraphicPrint
	bl LCD_SendFrameBuffer
	pop.n {pc}