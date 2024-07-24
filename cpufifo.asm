
; Envoit la donnée dans r0
; Récupère le retour dans r0

cpufifo_send:
	push.n {r1, r2}
	ldr.n r1, [cpufifo.write]
	str.n r0, [r1, #0]
	ldr.n r1, [cpufifo.status]
	movs r2, #1
;.wait: ; Attend que le fifo soit rempli.
	;ldr.n r0, [r1]
	;ands r0, r0, r2
	;beq .wait
	ldr.n r1, [cpufifo.read] ; Recupere la valeur
	ldr.n r0, [r1]
	pop.n {r1, r2}
	bx lr

align 4
cpufifo:
	.status: dw 0xd0000050
	.write: dw 0xd0000054
	.read: dw 0xd0000058