
CODE16

; Toutes les fonctions SPI prennent un paramètre en commun :
; Si R0 vaut 0, alors opération sur le controlleur SPI0, 
; Si R0 vaut tout autre valeur, alors opération sur le controlleur SPI1

;SPI defines

SPI_SSPCR0_Offset equ 0
SPI_SSPCR1_Offset equ 4
SPI_SSPCPSR_Offset equ 0x10
SPI_SSPDR_Offset equ 0x08
SPI_SSPSR_Offset equ 0x0C

; Initialise un transfert SPI 
; La fréquence du signal d'horloge finale est calculée : (ClockSource / Diviseur1) / Diviseur2
; R0 <- 0: Controlleur SPI0, 1: Controlleur SPI1
; R1[0:7] <- Diviseur 2 de la source d'horloge. Valeurs permises : 1-255
; R2[0:7] <- Diviseur 1 de la source d'horloge. Valeurs permises : Valeur paire obligatoire 2-254
; R3[0:4] <- Nombre de bit par frame. de 4 bits minimum à 16 bits.

SPI_Init:
	push.n {lr}
	push.n {r0, r1, r2, r3, r4}

	ldr.n r4, [SPI.SPI1_BASE]
	orrs r0, r0, r0 
	bne .l1 ; Si r0 vaut 1 alors sauter à la suite du code, sinon execute le code pour basculer sur SPI0.
	ldr.n r4, [SPI.SPI0_BASE]
.l1:

	; S'assure que le controlleur est désactivé pour faire des modifications.

	movs r0, #0000B
	str.n r0, [r4, #SPI_SSPCR1_Offset]

	; Configure control 0

	movs r0, r3 ; Nombre de bits par frame
	subs r0, r0, #1 ; Besoin de soustraire de 1. C'est comme ça. Demande pas pourquoi.
	lsls r1, r1, #8
	orrs r0, r0, r1 ; Colle le diviseur 2 à l'offset correspondant au diviseur 2 dans le registre.
	str.n r0, [r4, #SPI_SSPCR0_Offset]

	; Définit le clock prescale sur Diviseur 1

	str.n r2, [r4, #SPI_SSPCPSR_Offset]

	; Active le SPI

	movs r0, #0010B
	str.n r0, [r4, #SPI_SSPCR1_Offset]

	; Maintenant le controlleur SPI en question est initialisé.

	pop.n {r0, r1, r2, r3, r4}
	pop.n {pc}

; Envoit une donnée sur un controlleur SPI
; Et récupère la réponse.
; R0 <- 0: Controlleur SPI0, 1: Controlleur SPI1
; R1 <- Donné à envoyer en fonction du nombre de bits de la configuration.
; Retour : R1 prend la valeur de retour.

SPI_SendData:
	push.n {r0, r2}
	ldr.n r2, [SPI.SPI1_BASE]
	orrs r0, r0, r0 
	bne .l1 ; Si r0 vaut 1 alors sauter à la suite du code, sinon execute le code pour basculer sur SPI0.
	ldr.n r2, [SPI.SPI0_BASE]
.l1:
	str.n r1, [r2, #SPI_SSPDR_Offset] ; Envoit la donné
	; Attend la réponse.
.waitRNE: ; Attend que RNE soit à 1. (Donc qu'il y a qqch à lire)
	ldr.n r1, [r2, #SPI_SSPSR_Offset]
	movs r0, #(1 shl 2)
	ands r1, r1, r0
	lsrs r1, r1, #2
	beq .waitRNE ; Vaut 0 ? Attend encore.
	; Maintenant, récupère la valeur.
	ldr.n r1, [r2, #SPI_SSPDR_Offset]
	pop.n {r0, r2}
	bx lr


align 4

SPI:
.SPI1_BASE: DW 0x40040000
.SPI0_BASE: DW 0x4003c000