; Ce fichier contient les fonctions concernant le timer systeme.

; Configure le systick pour générer une interruption toute les microsecondes.
; Cettre interruption permetra au système de delay de marcher correctement.
systick_init:
	push.n {r0, r1}

	movs r0, #100 ; Parceque 100Mhz * 0.000001 = 100.
	ldr.n r1, [systick_rvr]
	str.n r0, [r1, #0]

	movs r0, #111B
	ldr.n r1, [systick_csr]
	str.n r0, [r1, #0]

	pop.n {r0, r1}
	bx lr

align 4
systick_rvr: dw 0xe000e014
systick_cvr: dw 0xe000e018
systick_csr: dw 0xe000e010
