CODE16

; Ce fichier contient les fonctions de division et de modulo.
; Ce fichier utilise la fonction SIO de division.

; Divise deux nombres non signés de 32 bits.

; R0 <- Dividende
; R1 <- Diviseur
; Retour : R0 <- Quotient

udiv32:
	push.n {r1,r2}
	ldr.n r2, [divider.SIO_DIVISOR_BASE]
	str.n r0, [r2, #0] ; Dividende
	str.n r1, [r2, #4] ; Diviseur
	movs r1, #1
.wait:
	ldr.n r0, [r2, #0x18] ; CSR
	ands r0, r0, r1
	beq .wait
	ldr.n r0, [r2, #0x10] ; Quotient
	pop.n {r1, r2}
	bx lr

; Divise deux nombres non signés de 32 bits et récupère le reste.

; R0 <- Dividende
; R1 <- Diviseur
; Retour : R0 <- Reste

umod32:
	push.n {r1,r2}
	ldr.n r2, [divider.SIO_DIVISOR_BASE]
	str.n r0, [r2, #0] ; Dividende
	str.n r1, [r2, #4] ; Diviseur
	movs r1, #1
.wait:
	ldr.n r0, [r2, #0x18] ; CSR
	ands r0, r0, r1
	beq .wait
	ldr.n r0, [r2, #0x14] ; Remainder
	pop.n {r1, r2}
	bx lr

align 4
divider:
	.SIO_BASE: DW 0xd0000000
	.SIO_DIVISOR_BASE: DW 0xD0000060