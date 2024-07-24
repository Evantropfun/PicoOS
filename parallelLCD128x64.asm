; Ce fichier est un driver pour le kernel permettant l'acces au LCD 16x4 en mode parallel.
; Pour le mode I2C, il faudra importer un autre fichier, le nom des fonctions sera le meme.
; Le driver utilise donc les GPIO0-10 sans altérer l'état des autres GPIO.
; La fonction d'initialisation s'occupe d'initialiser l'écran, et les gpio.

GPIO_OE_SET_Offset equ 0x24
GPIO_OE_CLR_Offset equ 0x28
GPIO_OUT_SET_Offset equ 0x14
GPIO_OUT_CLR_Offset equ 0x18
GPIO_OUT_Offset equ 0x10
SIO_IN_Offset equ 0x04
SIO_OE_CLR_Offset equ 0x28
SIO_OE_SET_Offset equ 0x24
SIO_OUT_SET_Offset equ 0x14
SIO_OUT_CLR_Offset equ 0x18

; 0 <- RS
; 1 <- E
; 2-9 <- data 0-7
; 10 <- RW

; Print en mode TTL pour le mode graphique. Offre beaucoup plus de place à l'écran.
; r1 <- Adresse de la chaine.

LCD_GraphicPrint:
	push.n {lr}
	push.n {r0, r1}

.loop:
	ldrb.n r0, [r1, #0]
	cmp r0, #0
	beq .end
	adds r1, #1
	bl LCD_PutChar
	b .loop
.end:

	pop.n {r0, r1}
	pop.n {PC}

; Print en mode TTL pour le mode graphique avec une longueur précisé. ( S'arretera quand même si rencontre un caractère 0. )
; r1 <- Adresse de la chaine.
; r2 <- Longueur.

LCD_GraphicPrintWithLenght:
	push.n {lr}
	push.n {r0, r1, r2}

.loop:
	ldrb.n r0, [r1, #0]
	cmp r0, #0
	beq .end
	adds r1, #1
	bl LCD_PutChar
	subs r2, r2, #1
	beq .end
	b .loop
.end:

	pop.n {r0, r1, r2}
	pop.n {PC}


; LCD_Init: Initialise l'écran et les GPIO.

LCD_InitGraphicMode:
	push.n {lr}
	; Ce code connecte les GPIO 0 - 10 au SIO.
	ldr.n r0, [LCD.GPIO_BASE]
	adds r0, r0, #4 ; Offset pour le registre de controle 0
	movs r1, #5 ; Valeur pour selectioner le SIO
	movs r2, #11 ; Valeur de compteur de la boucle
LCD_Init_loop:
	str.n r1, [r0, #0]
	adds r0, r0, #8 ; Offset à ajouter pour passer sur le GPIO suivant.
	subs r2, r2, #1 ; Cette instruction doit impérativement être avant le BNE.
	bne LCD_Init_loop ;Si le compteur ne vaut pas 0, revenir à la boucle.

	; Définit les GPIO 0 à 10 comme sortie.

	ldr.n r0, [LCD.SIO_BASE]

	movs r1, #111B ; Charge 0x03FF dans R1. 
	lsls r1, r1, #8
	movs r2, #0xFF
	orrs r1, r1, r2

	str.n r1, [r0, #GPIO_OE_SET_Offset] ; Définit GPIO0-9 en output ! : )

	;Maintenant que les GPIO sont OK, il faut initialiser l'écran.

	movs r1, #10B ; Décallage du GPIO1 correspondant à la broche E de l'écran.
	str.n r1, [r0, #GPIO_OUT_SET_Offset]

	movs r1, #1 ; Décalage pour la broche RS
	str.n r1, [r0, #GPIO_OUT_CLR_Offset] ; Positionne RS à 0.

	movs r0, #01100B ; Allumé, pas de curseur.
	bl LCD_SendCommand

	;movs r0, #1B ; Efface l'écran, en cas de reboot.
	;bl LCD_SendCommand

	movs r0, #110000B ; 4 lignes, Interface 8 bit
	bl LCD_SendCommand

	movs r0, #110100B ; 4 lignes, Instruction étendues
	bl LCD_SendCommand

	movs r0, #110110B ; 4 lignes, Mode graphique
	bl LCD_SendCommand

	movs r0, #111B; 
	bl LCD_SendCommand

	movs r0, #10B; 
	bl LCD_SendCommand

	push.n {r0}
	push.n {r1}

	bl delay ; Temps de l'instruction.
	bl delay ; Temps de l'instruction.
	pop.n {r1}
	pop.n {r0}
	pop.n {pc}

; Initialise l'écran en mode text.

LCD_InitTextMode:
	push.n {lr}
	; Ce code connecte les GPIO 0 - 10 au SIO.
	ldr.n r0, [LCD.GPIO_BASE]
	adds r0, r0, #4 ; Offset pour le registre de controle 0
	movs r1, #5 ; Valeur pour selectioner le SIO
	movs r2, #11 ; Valeur de compteur de la boucle
.Init_loop:
	str.n r1, [r0, #0]
	adds r0, r0, #8 ; Offset à ajouter pour passer sur le GPIO suivant.
	subs r2, r2, #1 ; Cette instruction doit impérativement être avant le BNE.
	bne .Init_loop ;Si le compteur ne vaut pas 0, revenir à la boucle.

	; Définit les GPIO 0 à 10 comme sortie.

	ldr.n r0, [LCD.SIO_BASE]

	movs r1, #111B ; Charge 0x03FF dans R1. 
	lsls r1, r1, #8
	movs r2, #0xFF
	orrs r1, r1, r2

	str.n r1, [r0, #GPIO_OE_SET_Offset] ; Définit GPIO0-9 en output ! : )

	;Maintenant que les GPIO sont OK, il faut initialiser l'écran.

	movs r1, #10B ; Décallage du GPIO1 correspondant à la broche E de l'écran.
	str.n r1, [r0, #GPIO_OUT_SET_Offset]

	movs r1, #1 ; Décalage pour la broche RS
	str.n r1, [r0, #GPIO_OUT_CLR_Offset] ; Positionne RS à 0.

	movs r0, #01100B ; Allumé, pas de curseur.
	bl LCD_SendCommand

	movs r0, #110000B ; 4 lignes, Interface 8 bit
	bl LCD_SendCommand

	push.n {r0}
	push.n {r1}

	bl delay ; Temps de l'instruction.
	bl delay ; Temps de l'instruction.
	pop.n {r1}
	pop.n {r0}
	pop.n {pc}

; Get the busy flag and return it in r0.

LCD_GetBusy:
	push.n {lr}
	bl LCD_ReadMode
	ldr.n r0, [LCD.SIO_BASE]
	ldr.n r0, [r0, #SIO_IN_Offset]
	lsrs r0, r0, #2
	uxtb r0, r0
	lsrs r0, r0, #7
	bl LCD_WriteMode
	pop.n {pc}



;Définit les pins d'I/O sur entrée et met R/W à 1. 
; PS : Ne pas changer l'ordre, sous risque de cramer le rp2040 ou l'écran.

LCD_ReadMode:
	push.n {r0, r1}

	; Pins de sortie sur 1.

	ldr.n r0, [LCD.SIO_BASE]
	adds r0, #SIO_OE_CLR_Offset
	movs r1, #0xFF
	lsls r1, r1, #2
	str.n r1, [r0, #0]

	; R/W à 1

	ldr.n r0, [LCD.SIO_BASE]
	adds r0, #SIO_OUT_SET_Offset
	movs r1, #1
	lsls r1, r1, #10
	str.n r1, [r0, #0]

	pop.n {r0, r1}
	bx lr

;met R/W à 0 et définit les pins d'I/O sur sortie. 
; PS : Ne pas changer l'ordre, sous risque de cramer le rp2040 ou l'écran.

LCD_WriteMode:
	push.n {r0, r1}

	; R/W à 0

	ldr.n r0, [LCD.SIO_BASE]
	adds r0, #SIO_OUT_CLR_Offset
	movs r1, #1
	lsls r1, r1, #10
	str.n r1, [r0, #0]

	; Pins de sortie sur 1.

	ldr.n r0, [LCD.SIO_BASE]
	adds r0, #SIO_OE_SET_Offset
	movs r1, #0xFF
	lsls r1, r1, #2
	str.n r1, [r0, #0]

	pop.n {r0, r1}
	bx lr


LCD_SetRS:
	push.n {r0, r2}
	ldr.n r0, [LCD.SIO_BASE]
	movs r2, #1 ; Décalage pour la broche RS
	str.n r2, [r0, #GPIO_OUT_SET_Offset]
	pop.n {r0, r2}
	bx lr

; Désactive RS.

LCD_ClearRS:
	push.n {r0, r2}
	ldr.n r0, [LCD.SIO_BASE]
	movs r2, #1 ; Décalage pour la broche RS
	str.n r2, [r0, #GPIO_OUT_CLR_Offset]
	pop.n {r0, r2}
	bx lr

; Efface le framebuffer

LCD_Clear:
	push.n {r0, r1, r2}
	ldr.n r1, [LCD.FrameBufferAddr]
	ldr.n r2, [.count]
	movs r0, #0
.loop:
	strb.n r0, [r1]
	adds r1, r1, #1
	subs r2, r2, #1
	bne .loop
	pop.n {r0, r1, r2}
	bx lr
	align 4
	.count: dw 1024

; Dessine une image de 8 par 8 pixels sur le framebuffer.
; r0 <- x
; r1 <- y
; r2 <- Adresse de l'image. (8 octets.)

LCD_DrawImage8x8:
	push.n {lr}
	push.n {r3}
	movs r3, #8
	bl LCD_DrawImage8
	pop.n {r3}
	pop.n {pc}


; Dessine une image de 8 pixels de larges sur le framebuffer.
; r0 <- x
; r1 <- y
; r2 <- Adresse de l'image. (8 octets.)
; r3 <- Longueur de l'image.

LCD_DrawImage8:
	push.n {lr}
	push.n {r1, r2, r3, r4, r5, r6}
.loop:
	ldrb.n r4, [r2]
	adds r2, r2, #1
	movs r5, r0
	movs r6, r1
	adds r1, r1, #1
	bl LCD_PutByte
	subs r3, r3, #1
	bne .loop
	pop.n {r1, r2, r3, r4, r5, r6}
	pop.n {pc}

; Dessine un caractère 3x5 avec les fonts prédéfini.
; r0 <- Numéro du caractère selon la table ascii.
; r1 <- X ( J'espère ta pas oublié des tes cours de math frere)
; r2 <- Y

LCD_DrawChar:
	push.n {lr}
	push.n {r0, r1, r2, r3}
	; Calcul l'adresse du caractère.
	movs r3, #5
	muls r0, r3
	ldr.n r3, [LCD.FontAddr]
	adds r0, r0, r3

	movs r3, r2 ; backup Y
	movs r2, r0 ; Adresse
	movs r0, r1 ; x
	movs r1, r3 ; y
	movs r3, #5 ; 5 lignes
	bl LCD_DrawImage8

	pop.n {r0, r1, r2, r3}
	pop.n {PC}

; Dessine un caractère en mode TTY.
; R0 <- Numéro ASCII

LCD_PutChar:
	push.n {lr}
	push.n {r1, r2, r3}

	ldr.n r3, [LCD.GraphicTextModeCursorAddr]
	ldr.n r1, [r3, #0]
	ldr.n r2, [r3, #4]

	cmp r0, #10
	beq .clearR1

	bl LCD_DrawChar

	adds r1, #4
	cmp r1, #128-4
	beq .clearR1

	str.n r1, [r3, #0]

	pop.n {r1, r2, r3}
	pop.n {pc}
.clearR1: ; Saut de ligne
	movs r1, #0
	adds r2, #5
	str.n r1, [r3, #0]
	str.n r2, [r3, #4]
	pop.n {r1, r2, r3}
	pop.n {pc}



; Pose un octet sur le frame buffer à une adresse x y.
; Note ; Fais une opération OR
; r4[7:0] <- valeur
; r5 <- x
; r6 <- y.

LCD_PutByte:

	push.n {lr}
	push.n {r0, r1, r2, r3, r4, r5, r7}
	
	; Converti les coordonnées en un offset sur le fb.

	movs r0, r5
	movs r1, #8
	bl umod32
	movs r7, r0 ; Met dans R7 le reste de la division
	movs r0, r5
	bl udiv32
	movs r5, r0 ; Met dans R8 le résultat de X/8

	movs r0, #16
	muls r0, r6
	adds r0, r5 ; Maintenant, r0 contient l'offset.

	ldr.n r1, [LCD.FrameBufferAddr]
	adds r1, r1, r0 ; Réupère l'adresse du fb en ajoutant l'offset
	ldrb.n r2, [r1] ; Récupère la valeur se trouvant à l'adresse en question pour le or
	movs r3, r4 ; Met r4 dans r3 afin de récupèrer seuls les bits nous intéressant.
	lsrs r3, r3, r7
	orrs r2, r2, r3
	strb.n r2, [r1]

	ldrb.n r2, [r1, #1] ; Place les pixels qui dépassent
	movs r3, #8
	subs r3, r3, r7
	lsls r4, r4, r3
	orrs r2, r2, r4
	strb.n r2, [r1, #1]


	pop.n {r0, r1, r2, r3, r4, r5, r7}
	pop.n {pc}

; Pose un octet sur le frame buffer à une adresse x y.
; Note ; Fais une opération OR
; r4[7:0] <- valeur
; r5 <- x.
; r6 <- y.

LCD_PutByteClr:

	push.n {lr}
	push.n {r0, r1, r2, r3, r4, r5, r7}
	
	; Converti les coordonnées en un offset sur le fb.

	movs r0, r5
	movs r1, #8
	bl umod32
	movs r7, r0 ; Met dans R7 le reste de la division
	movs r0, r5
	bl udiv32
	movs r5, r0 ; Met dans R8 le résultat de X/8

	movs r0, #16
	muls r0, r6
	adds r0, r5 ; Maintenant, r0 contient l'offset.

	ldr.n r1, [LCD.FrameBufferAddr]
	adds r1, r1, r0 ; Réupère l'adresse du fb en ajoutant l'offset
	ldrb.n r2, [r1] ; Récupère la valeur se trouvant à l'adresse en question pour le or
	bl LCD_ReverseR2
	movs r3, r4 ; Met r4 dans r3 afin de récupèrer seuls les bits nous intéressant.
	lsrs r3, r3, r7
	orrs r2, r2, r3
	bl LCD_ReverseR2
	strb.n r2, [r1]

	ldrb.n r2, [r1, #1] ; Place les pixels qui dépassent
	bl LCD_ReverseR2
	movs r3, #8
	subs r3, r3, r7
	lsls r4, r4, r3
	orrs r2, r2, r4
	bl LCD_ReverseR2
	strb.n r2, [r1, #1]


	pop.n {r0, r1, r2, r3, r4, r5, r7}
	pop.n {pc}

; reverse R2.

LCD_ReverseR2:
	push.n {r0}
	movs r0, #0xFF
	eors r2, r0
	pop.n {r0}
	bx lr



LCD_SendFrameBuffer:
	push.n {lr}
	push.n {r0, r1, r2, r3, r4, r5, r6, r7}
	; Send first 512 bytes.

	ldr.n r1, [LCD.FrameBufferAddr]

	movs r7, #10000000B ; Command for x
.otherloop:

	movs r4, #0 ; Y
	movs r3, #0 ; x
	movs r5, #16 ; width
	movs r6, #32 ; height

	bl LCD_ClearRS

	movs r0, #10000000B ; Y
	bl LCD_SendCommand
	movs r0, r7 ; X
	bl LCD_SendCommand

	bl LCD_SetRS
.lineLoop:
	ldrb.n r0, [r1, r3]
	bl LCD_SendCommand
	adds r3, r3, #1
	cmp r3, r5
	bne .lineLoop

	bl LCD_ClearRS
	adds r4, r4, #1
	movs r0, #10000000B ; Y
	orrs r0, r0, r4
	bl LCD_SendCommand
	movs r0, r7 ; X
	bl LCD_SendCommand
	adds r1, r1, #16
	movs r3, #0
	bl LCD_SetRS
	cmp r4, r6
	bne .lineLoop

	movs r0, #10001000B
	cmp r0, r7
	beq .end
	movs r7, r0
	b .otherloop
.end:
	pop.n {r0, r1, r2, r3, r4, r5, r6, r7}
	pop.n {pc}

; LCD_Send16Char : Fonction nécéssaire pour LCD_SendTextBuffer
; S'occupe d'envoyer 16 caratères et ajoute 16 à r3.
; r3 <- Adresse des 16 caractères à envoyer.
; Note : RS doit être préinitialiser à 1.

LCD_Send16Char:
	push.n {lr}
	push.n {r0, r1}
	movs r1, #16+1
.loop:
	ldrb.n r0, [r3, #0]
	subs r1, r1, #1
	beq .end
	bl LCD_SendCommand
	adds r3, r3, #1
	b .loop
.end:
	pop.n {r0, r1}
	pop.n {pc}

; LCD_FrameBufferShiftUp: Décale le frame buffer vers le haut pour le scrolling. Le dernière ligne est effacée.
; Aucun paramètres nécéssaire.

LCD_FrameBufferShiftUp:
	push.n {lr}
	push.n {r0, r2, r3}
	ldr.n r3, [LCD_FrameBuffer.addr] ; Récupère l'adresse du fb.
	movs r2, #16*4
.loop:
	ldrb.n r0, [r3, #16] ; Prend les caractères une ligne en dessous
	strb.n r0, [r3, #0] ; Et les remets une ligne au dessus.
	adds r3, r3, #1
	subs r2, r2, #1
	bne .loop
	pop.n {r0, r2, r3}
	pop.n {pc}



; LCD_print: Envoit une chaine de caractère, avec scrolling. Une ligne à la fois.
; r1 <- Adresse de la chaine.

LCD_print:
	push.n {lr}
	push.n {r0, r1, r2, r3, r4}
	bl LCD_FrameBufferShiftUp ; Décale l'écran vers le haut.
	ldr.n r3, [LCD_FrameBuffer.addr] ; Adresse du framebuffer.
	adds r3, r3, #48
	movs r4, #10
LCD_SendStringLoop:
	ldrb.n r0, [r1, #0]
	adds r1, r1, #1
	cmp r0, r4
	beq .linefeed
	orrs r0, r0, r0
	beq LCD_SendStringLoopEnd
	strb.n r0, [r3, #0]
	adds r3, r3, #1
	b LCD_SendStringLoop
.linefeed: ; Passage à la ligne.
	bl LCD_FrameBufferShiftUp
	ldr.n r3, [LCD_FrameBuffer.addr] ; Recharge l'adresse du framebuffer. 
	adds r3, r3, #48
	b LCD_SendStringLoop
LCD_SendStringLoopEnd:

	bl LCD_SendTextBuffer
	pop.n {r0, r1, r2, r3, r4}
	pop.n {pc}

; LCD_SendTextBuffer : Envoit le frame buffer mode text à l'écran, en faisant les conversions.

LCD_SendTextBuffer:
	push.n {lr}
	push.n {r0, r3}

	bl LCD_ClearRS ; Mode commande

	ldr.n r3, [LCD_FrameBuffer.addr] ; Récupère l'adresse du framebuffer
	movs r0, #0x80
	bl LCD_SendCommand ;Première ligne

	bl LCD_SetRS ; Mode caractère

	; Envoit de la première ligne :
	bl LCD_Send16Char

	bl LCD_ClearRS ; Mode commande
	movs r0, #0x90
	bl LCD_SendCommand ;Deuxième ligne
	bl LCD_SetRS ; Mode caractère
	; Envoit de la deuxième ligne :
	bl LCD_Send16Char

	bl LCD_ClearRS ; Mode commande
	movs r0, #0x88
	bl LCD_SendCommand ;Troisième ligne
	bl LCD_SetRS ; Mode caractère
	; Envoit de la troisième ligne :
	bl LCD_Send16Char

	bl LCD_ClearRS ; Mode commande
	movs r0, #0x98
	bl LCD_SendCommand ;Quatrieme ligne
	bl LCD_SetRS ; Mode caractère
	; Envoit de la quatrieme ligne :
	bl LCD_Send16Char

	pop.n {r0, r3}
	pop.n {pc}

; Return text frame buffer address in R0.

LCD_GetTextFrameBuffer:
	ldr.n r0, [LCD_FrameBuffer.addr]
	bx lr

align 4
LCD_FrameBuffer:
times (16*5) db ' ' ; L'écran fait 4 lignes, mais j'ai ajouté une 5 ème ligne dans le FB qui sert pour simplifier le code de scrolling.
.addr: DW LCD_FrameBuffer

; LCD_SendCommand: Envoit une commande ou une donné 8 bit au lcd. 
; Note : Il faut définir à l'avance l'état du pin RS.
; R0 <- Commande à envoyer.

LCD_SendCommand:
	push.n {lr}
	push.n {r0, r1, r2, r3}

	ldr.n r3, [LCD.SIO_BASE] ; Récupère l'adresse de base SIO.

	; Met les données sur le bus de l'écran.
	bl XOSC_Delay72us
	bl XOSC_Delay72us
	uxtb r0, r0 ; Ne garde que les 8 premiers bits pour ne pas altérer les autres I/O.
	lsls r0, r0, #2 ; Décale de 2 bits pour correspondre aux GPIO 2 à 9 inclu.
	ldr.n r1, [r3, #GPIO_OUT_Offset] ; Je suis obligé de faire un read-modify-write ici.
	ldr.n r2, [LCD.SendCommandFilter] ; Charge le filtre dans R2 et l'applique à R1, pour mettre à 0 les bits de data.
	ands r1, r1, r2
	orrs r1, r1, r0 ; Met les bits de R0 à la place de ceux que l'on vient d'enlever.
	str.n r1, [r3, #GPIO_OUT_Offset] ; Termine la séquence read-modify-write.
	bl XOSC_Delay72us
	; Génère la pulse sur le pin E.

	movs r1, #10B ; Décallage du GPIO1 correspondant à la broche E de l'écran.
	str.n r1, [r3, #GPIO_OUT_CLR_Offset]
	bl XOSC_Delay72us
	bl XOSC_Delay72us
	bl XOSC_Delay72us
	bl XOSC_Delay72us
	bl XOSC_Delay72us
	bl XOSC_Delay72us
	str.n r1, [r3, #GPIO_OUT_SET_Offset]

	pop.n {r0, r1, r2, r3}
	pop.n {PC}

; Return frame buffer address in R0.

LCD_GetFrameBuffer:
	ldr.n r0, [LCD.FrameBufferAddr]
	bx lr

align 4

LCD:
	.FontAddr: dw (.Font) - (32*5) ;
	.GraphicTextModeCursorAddr: dw .GraphicTextModeCursor
	.GraphicTextModeCursor: dw 0 ; x
						    dw 0 ; y
	.SendCommandFilter: DW 0xFFFFFC03
	.GPIO_BASE DW 0x40014000
	.SIO_BASE DW 0xD0000000
	.FrameBufferAddr: dw .FrameBuffer
	.FrameBuffer:
		times 1024 db 0
	.Font: ; Font par défaut de la lib pour le mode graphique qui offre bien plus d'espace.

	times 5 db 0 ; Espace

	db 01000000B ; !
	db 01000000B
	db 00000000B
	db 01000000B
	db 00000000B

	db 10100000B ; "
	db 10100000B
	db 00000000B
	db 00000000B
	db 00000000B

	db 10100000B ; #
	db 11100000B ; ça ressemble pas, je sais
	db 10100000B
	db 11100000B
	db 10100000B

	db 11100000B ; $
	db 11000000B
	db 01100000B
	db 11100000B
	db 00000000B

	db 10100000B ; %
	db 00100000B
	db 11000000B
	db 10100000B
	db 00000000B

	db 01000000B ; &
	db 01100000B
	db 11000000B
	db 01100000B
	db 00000000B

	db 01000000B ; '
	db 01000000B
	db 00000000B
	db 00000000B
	db 00000000B

	db 01000000B ; (
	db 10000000B
	db 10000000B
	db 01000000B
	db 00000000B

	db 01000000B ; )
	db 00100000B
	db 00100000B
	db 01000000B
	db 00000000B

	db 00000000B ; *
	db 11100000B
	db 11100000B
	db 11100000B
	db 00000000B

	db 00000000B ; +
	db 01000000B
	db 11100000B
	db 01000000B
	db 00000000B

	db 00000000B ; ,
	db 00000000B
	db 00000000B
	db 00100000B
	db 01100000B

	db 00000000B ; -
	db 00000000B
	db 11100000B
	db 00000000B
	db 00000000B

	db 00000000B ; .
	db 00000000B
	db 00000000B
	db 01000000B
	db 00000000B

	db 00100000B ; /
	db 01000000B
	db 01000000B
	db 10000000B
	db 00000000B

	db 11100000B ; 0
	db 10100000B
	db 10100000B
	db 11100000B
	db 00000000B

	db 11000000B ; 1
	db 01000000B
	db 01000000B
	db 01000000B
	db 00000000B

	db 11100000B ; 2
	db 00100000B
	db 11000000B
	db 11100000B
	db 00000000B

	db 11100000B ; 3
	db 01100000B
	db 00100000B
	db 11100000B
	db 00000000B

	db 10100000B ; 4
	db 10100000B
	db 11100000B
	db 00100000B
	db 00000000B

	db 11100000B ; 5
	db 11000000B
	db 00100000B
	db 11100000B
	db 00000000B

	db 11100000B ; 6
	db 10000000B
	db 11100000B
	db 11100000B
	db 00000000B

	db 11100000B ; 7
	db 00100000B
	db 01100000B
	db 00100000B
	db 00000000B

	db 11100000B ; 8
	db 11100000B
	db 10100000B
	db 11100000B
	db 00000000B

	db 11100000B ; 9
	db 11100000B
	db 00100000B
	db 11100000B
	db 00000000B ;

	db 00000000B ; :
	db 01000000B
	db 00000000B
	db 01000000B
	db 00000000B

	db 00000000B ; ;
	db 01000000B
	db 00000000B
	db 01000000B
	db 11000000B

	db 00000000B ; <
	db 01100000B
	db 10000000B
	db 01100000B
	db 00000000B

	db 00000000B ; =
	db 11100000B
	db 00000000B
	db 11100000B
	db 00000000B

	db 00000000B ; >
	db 11000000B
	db 00100000B
	db 11000000B
	db 00000000B

	db 11100000B ; ?
	db 00100000B
	db 00000000B
	db 01000000B
	db 00000000B

	db 11100000B ; @ ne sera pas supporté.
	db 00100000B
	db 00000000B
	db 01000000B
	db 00000000B

	db 11100000B ; A
	db 10100000B 
	db 11100000B 
	db 10100000B 
	db 00000000B

	db 11000000B ; B
	db 11100000B 
	db 10100000B 
	db 11100000B
	db 00000000B 

	db 11100000B ; C
	db 10000000B 
	db 10000000B 
	db 11100000B 
	db 00000000B 

	db 11000000B ; D
	db 10100000B 
	db 10100000B 
	db 11000000B 
	db 00000000B 

	db 11100000B ; E
	db 11000000B 
	db 10000000B 
	db 11100000B 
	db 00000000B 

	db 11100000B ; F
	db 10000000B 
	db 11000000B 
	db 10000000B 
	db 00000000B 

	db 11100000B ; G
	db 10000000B 
	db 10100000B 
	db 11100000B 
	db 00000000B 

	db 10100000B ; H
	db 11100000B 
	db 10100000B 
	db 10100000B 
	db 00000000B 

	db 11100000B ; I
	db 01000000B 
	db 01000000B 
	db 11100000B 
	db 00000000B 

	db 11100000B ; J
	db 01000000B 
	db 01000000B 
	db 11000000B 
	db 00000000B 

	db 10100000B ; K
	db 11000000B 
	db 11000000B 
	db 10100000B 
	db 00000000B 

	db 10000000B ; L
	db 10000000B 
	db 10000000B 
	db 11100000B 
	db 00000000B 

	db 11100000B ; M
	db 11100000B 
	db 11100000B 
	db 10100000B 
	db 00000000B 

	db 11100000B ; N
	db 10100000B 
	db 10100000B 
	db 10100000B 
	db 00000000B 

	db 11100000B ; O
	db 10100000B 
	db 10100000B 
	db 11100000B 
	db 00000000B

	db 11100000B ; P
	db 10100000B 
	db 11100000B 
	db 10000000B 
	db 00000000B

	db 11100000B ; Q
	db 10100000B 
	db 11100000B 
	db 00100000B 
	db 00000000B

	db 11100000B ; R
	db 11100000B
	db 11000000B
	db 10100000B
	db 00000000B

	db 11100000B ; S
	db 10000000B
	db 01100000B
	db 11100000B
	db 00000000B

	db 11100000B ; T
	db 01000000B
	db 01000000B
	db 01000000B
	db 00000000B

	db 10100000B ; U
	db 10100000B
	db 10100000B
	db 11100000B
	db 00000000B

	db 10100000B ; V
	db 10100000B
	db 10100000B
	db 01000000B
	db 00000000B

	db 10100000B ; W
	db 11100000B
	db 11100000B
	db 11100000B
	db 00000000B	

	db 10100000B ; X
	db 11000000B
	db 01100000B
	db 10100000B
	db 00000000B

	db 10100000B ; Y
	db 11100000B
	db 01000000B
	db 01000000B
	db 00000000B

	db 11100000B ; Z
	db 01100000B
	db 10000000B
	db 11100000B
	db 00000000B

	db 11100000B ; [
	db 10000000B
	db 10000000B
	db 11100000B
	db 00000000B

	db 10000000B ; \
	db 01000000B
	db 01000000B
	db 00100000B
	db 00000000B

	db 11100000B ; ]
	db 00100000B
	db 00100000B
	db 11100000B
	db 00000000B

	db 01000000B ; ^
	db 10100000B
	db 00000000B
	db 00000000B
	db 00000000B

	db 00000000B ; _
	db 00000000B
	db 00000000B
	db 11100000B
	db 00000000B

	db 10000000B ; `
	db 01000000B
	db 00000000B
	db 00000000B
	db 00000000B

	db 00000000B ; a
	db 01100000B
	db 11100000B
	db 11100000B
	db 00000000B

	db 10000000B ; b
	db 11100000B
	db 10100000B
	db 11100000B
	db 00000000B

	db 00000000B ; c
	db 11100000B
	db 10000000B
	db 11100000B
	db 00000000B

	db 00100000B ; d
	db 11100000B
	db 10100000B
	db 11100000B
	db 00000000B

	db 00000000B ; e
	db 11000000B
	db 11000000B
	db 11100000B
	db 00000000B

	db 01100000B ; f
	db 01000000B
	db 11100000B
	db 01000000B
	db 00000000B

	db 00000000B ; g
	db 11100000B
	db 11100000B
	db 00100000B
	db 11100000B

	db 10000000B ; h
	db 11100000B
	db 10100000B
	db 10100000B
	db 00000000B

	db 01000000B ; i
	db 00000000B
	db 01000000B
	db 01000000B
	db 00000000B

	db 01000000B ; j
	db 00000000B
	db 01000000B
	db 01000000B
	db 11000000B

	db 10000000B ; k
	db 10100000B
	db 11000000B
	db 10100000B
	db 00000000B

	db 10000000B ; l
	db 10000000B
	db 10000000B
	db 11000000B
	db 00000000B

	db 00000000B ; m
	db 11100000B
	db 11100000B
	db 10100000B
	db 00000000B

	db 00000000B ; n
	db 11100000B
	db 10100000B
	db 10100000B
	db 00000000B

	db 00000000B ; o
	db 11100000B
	db 10100000B
	db 11100000B
	db 00000000B

	db 00000000B ; p
	db 11100000B
	db 10100000B
	db 11100000B
	db 10000000B

	db 00000000B ; q
	db 11100000B
	db 10100000B
	db 11100000B
	db 00100000B

	db 00000000B ; r
	db 11100000B
	db 10000000B
	db 10000000B
	db 00000000B

	db 00000000B ; s
	db 01100000B
	db 01000000B
	db 11000000B
	db 00000000B

	db 01000000B ; t
	db 11100000B
	db 01000000B
	db 01100000B
	db 00000000B

	db 00000000B ; u
	db 10100000B
	db 10100000B
	db 11100000B
	db 00000000B

	db 00000000B ; v
	db 10100000B
	db 10100000B
	db 01000000B
	db 00000000B

	db 00000000B ; w
	db 10100000B
	db 11100000B
	db 11100000B
	db 00000000B

	db 00000000B ; x
	db 10100000B
	db 01000000B
	db 10100000B
	db 00000000B

	db 00000000B ; y
	db 10100000B
	db 11100000B
	db 00100000B
	db 11000000B

	db 00000000B ; z
	db 11100000B
	db 01000000B
	db 00100000B
	db 11000000B