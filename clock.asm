CODE16

; Contient toute les fonctions concernant la génération des signaux d'horloge pour les différents périfériques.

CLOCK_SwitchCLKREFonXOSC: ; Passe la CLKREF sur le XOSC. Celui doit être initialisé avant.
	push.n {r0, r1}
	movs r0, #2 ; 2 correspondant au XOSC.
	ldr.n r1, [CLOCK.CLK_REF_CTRL]
	str.n r0, [r1, #0]

	movs r0, #1
	lsls r0, r0, #8
	ldr.n r1, [CLOCK.CLK_REF_DIV] ; S'assure que la clock ne soit pas divisée.
	str.n r0, [r1, #0]

	pop.n {r0, r1}
	bx lr

; Démarre la clock CLKPERI
; Très utile, à mon avis, pour les périfériques.

CLOCK_StartCLKPERI:
	push.n {r0, r1}
	ldr.n r0, [CLOCK.CLK_PERI_CTRL_SET]
	movs r1, #1
	lsls r1, r1, #11
	str.n r1, [r0]
	pop.n {r0, r1}
	bx lr

CLOCK_SwitchCLKSYSonPLL:
	push.n {r0, r1}
	ldr.n r0, [CLOCK.CLK_SYS_CTRL]
	movs r1, #1
	str.n r1, [r0]
	pop.n {r0, r1}
	bx lr

; Connecte la clock de l'ADC au Pll USB et la démarre.

CLOCK_SwitchCLKADConPLL:
	push.n {r0, r1}
	ldr.n r0, [CLOCK.CLK_ADC_CTRL]
	movs r1, #1
	lsls r1, r1, #11 ; Offset du enable.
	; Le reste du registre est à 0, car 0 correspond de toute façon au pll usb.
	str.n r1, [r0]
	pop.n {r0, r1}
	bx lr

align 4

CLOCK:
	.CLK_SYS_CTRL: DW 0x4000803C
	.CLK_ADC_CTRL: DW 0x40008060
	.CLK_REF_DIV: DW 0x40008034
	.CLK_REF_CTRL: DW 0x40008030
	.CLK_PERI_CTRL_SET: DW (0x40008048 + 0x2000)