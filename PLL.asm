CODE16

; Ce fichier contient les fonctions d'initilisations des PLL.
; C'est à dire, la fonction pour initialiser l'USB PLL à 48Mhz
; et aussi la fonction pour initialiser le SYS PLL à 133Mhz (100Mhz pour l'instant.)

; Initalise USB PLL à 48Mhz
PLL_InitUSB:
	push.n {r0, r1}
	; Met fbdiv à 100

	ldr.n r1, [PLL.pll_usb_base]
	movs r0, #64
	str.n r0, [r1, #8] ; Offset de fbdiv

	; Postiv 1 à 6 et Postdiv 2 à 2

	ldr.n r0, [.pll_postdiv_conf]
	str.n r0, [r1, #0xC]

	movs r0, #100B ; Met PWR à 0
	str.n r0, [r1, #4]

	pop.n {r0, r1}
	bx lr
	align 4
.pll_postdiv_conf: dw (4 shl 16) or (4 shl 12) 

; Initalise SYS PLL à 100Mhz
PLL_InitSys:
	push.n {r0, r1}
	; Met fbdiv à 100

	ldr.n r1, [PLL.pll_sys_base]
	movs r0, #100
	str.n r0, [r1, #8]

	; Postiv 1 à 6 et Postdiv 2 à 2

	ldr.n r0, [.pll_postdiv_conf]
	str.n r0, [r1, #0xC]

	movs r0, #100B ; Met PWR à 0
	str.n r0, [r1, #4]

	pop.n {r0, r1}
	bx lr
	align 4
.pll_postdiv_conf: dw (6 shl 16) or (2 shl 12) 

align 4
PLL:
	.pll_sys_base: dw 0x40028000
	.pll_usb_base: dw 0x4002c000
	