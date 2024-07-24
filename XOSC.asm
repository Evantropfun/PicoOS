CODE16

XOSC_CTRL_Offset equ 0x00
XOSC_STATUS_Offset equ 0x04
XOSC_STARTUP_Offset equ 0x0c
XOSC_COUNT_Offset equ 0x1c

; Contient les fonctions permettant l'utilisation du XOSC.

XOSC_Init: ;Initialise le XOSC, à une fréquence de 12Mhz sur une carte Raspberry pico classique. cette fonction créé un delai d'environ 1 milliseconde pour la mise en route du quartz. Les PLL devront être initialisé pour espérer monter à 128Mhz.
	push.n {r0, r1}
	ldr.n r0, [XOSC_BASE]
	movs r1, #47
	str.n r1, [r0, #XOSC_STARTUP_Offset]

	ldr.n r1, [XOSC_CTRL_Config]
	str.n r1, [r0, #XOSC_CTRL_Offset]
.wait:
	ldr.n r1, [r0, #XOSC_STATUS_Offset]
	lsrs r1, r1, #31
	beq .wait
	pop.n {r0, r1}
	bx lr

; Cette fonction génère un delai d'une seconde, exactement.

XOSC_DelayOneSec:
	push.n {r0, r1, r2}
	ldr.n r0, [XOSC_BASE]
	ldr.n r2, [.valForCounter]
.loop:
	movs r1, 0xFF
	str.n r1, [r0, XOSC_COUNT_Offset] ; déclenche un compteur.
.wait:
	ldr.n r1, [r0, XOSC_COUNT_Offset]
	orrs r1, r1, r1
	bne .wait
	subs r2, r2, #1
	bne .loop
	pop.n {r0, r1, r2}
	bx lr
align 4
.valForCounter: ; Nombre de compteurs de 255 à faire. 255x47058 = 12000000 soit 1 seconde.
	DW 392156;47058

; Cette fonction génère un delai d'une de 72 microsecondes.

XOSC_Delay72us:
	push.n {r0, r1, r2}
	ldr.n r0, [XOSC_BASE]
	ldr.n r2, [.valForCounter]
.loop:
	movs r1, 0xFF
	str.n r1, [r0, XOSC_COUNT_Offset] ; déclenche un compteur.
.wait:
	ldr.n r1, [r0, XOSC_COUNT_Offset]
	orrs r1, r1, r1
	bne .wait
	subs r2, r2, #1
	bne .loop
	pop.n {r0, r1, r2}
	bx lr
align 4
.valForCounter: ; Nombre de compteurs de 255 à faire. 255x47058 = 12000000 soit 1 seconde.
	DW 4

align 4

XOSC_BASE: DW 0x40024000
XOSC_CTRL_Config: DW 111110101011101010100000B