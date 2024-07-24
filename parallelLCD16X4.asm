CODE16

; Ce fichier est un driver pour le kernel permettant l'acces au LCD 16x4 en mode parallel.
; Pour le mode I2C, il faudra importer un autre fichier, le nom des fonctions sera le meme.
; Le driver utilise donc les GPIO0-9 sans altérer l'état des autres GPIO.
; La fonction d'initialisation s'occupe d'initialiser l'écran, et les gpio.

; LCD_Init: Initialise l'écran et les GPIO.

LCD_Init:
	push.n {lr}
	; Ce code connecte les GPIO 0 - 9 au SIO.
	ldr.n r0, [LCD.GPIO_BASE]
	adds r0, r0, #4 ; Offset pour le registre de controle 0
	movs r1, #5 ; Valeur pour selectioner le SIO
	movs r2, #10 ; Valeur de compteur de la boucle
LCD_Init_loop:
	str.n r1, [r0, #0]
	adds r0, r0, #8 ; Offset à ajouter pour passer sur le GPIO suivant.
	subs r2, r2, #1 ; Cette instruction doit impérativement être avant le BNE.
	bne LCD_Init_loop ;Si le compteur ne vaut pas 0, revenir à la boucle.

	; Définit les GPIO 0 à 9 comme sortie.

	ldr.n r0, [LCD.SIO_BASE]

	movs r1, #3 ; Charge 0x03FF dans R1. 
	lsls r1, r1, #8
	movs r2, #0xFF
	orrs r1, r1, r2

	str.n r1, [r0, #GPIO_OE_SET_Offset] ; Définit GPIO0-9 en output ! : )

	;Maintenant que les GPIO sont OK, il faut initialiser l'écran.

	movs r1, #10B ; Décallage du GPIO1 correspondant à la broche E de l'écran.
	str.n r1, [r0, #GPIO_OUT_SET_Offset]

	movs r1, #1 ; Décalage pour la broche RS
	str.n r1, [r0, #GPIO_OUT_CLR_Offset] ; Positionne RS à 0.

	push.n {r0}
	push.n {r1}

	bl delay ; Temps de l'instruction.

	;Met la broche RS à 0 pour le mode instruction

	movs r0, #0x0C ; Ecran allumé, pas de curseur, car c'est moche.
	bl LCD_SendCommand


	bl delay ; Temps de l'instruction.

	movs r0, #111000B ; 4 lignes, caractères 5x8
	bl LCD_SendCommand

	bl delay ; Temps de l'instruction.

	movs r0, #1B ; Efface l'écran, en cas de reboot.
	bl LCD_SendCommand

	bl delay ; Temps de l'instruction.
	pop.n {r1}
	pop.n {r0}
	pop.n {pc}

; Active RS.

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

	bl LCD_SendFrameBuffer
	pop.n {r0, r1, r2, r3, r4}
	pop.n {pc}

; LCD_Send16Char : Fonction nécéssaire pour LCD_SendFrameBuffer
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

; LCD_SendFrameBuffer : Envoit le frame buffer à l'écran, en faisant les conversions.

LCD_SendFrameBuffer:
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
	movs r0, #0xC0
	bl LCD_SendCommand ;Deuxième ligne
	bl LCD_SetRS ; Mode caractère
	; Envoit de la deuxième ligne :
	bl LCD_Send16Char

	bl LCD_ClearRS ; Mode commande
	movs r0, #0x90
	bl LCD_SendCommand ;Troisième ligne
	bl LCD_SetRS ; Mode caractère
	; Envoit de la troisième ligne :
	bl LCD_Send16Char

	bl LCD_ClearRS ; Mode commande
	movs r0, #0xD0
	bl LCD_SendCommand ;Quatrieme ligne
	bl LCD_SetRS ; Mode caractère
	; Envoit de la quatrieme ligne :
	bl LCD_Send16Char

	pop.n {r0, r3}
	pop.n {pc}



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

	uxtb r0, r0 ; Ne garde que les 8 premiers bits pour ne pas altérer les autres I/O.
	lsls r0, r0, #2 ; Décale de 2 bits pour correspondre aux GPIO 2 à 9 inclu.
	ldr.n r1, [r3, #GPIO_OUT_Offset] ; Je suis obligé de faire un read-modify-write ici.
	ldr.n r2, [LCD_SendCommandFilter] ; Charge le filtre dans R2 et l'applique à R1, pour mettre à 0 les bits de data.
	ands r1, r1, r2
	orrs r1, r1, r0 ; Met les bits de R0 à la place de ceux que l'on vient d'enlever.
	str.n r1, [r3, #GPIO_OUT_Offset] ; Termine la séquence read-modify-write.

	push.n {r0}
	push.n {r1}
	bl delay ; Appelle delay pour laisser le temps à l'écran de respirer.
	pop.n {r1}
	pop.n {r0}

	; Génère la pulse sur le pin E.

	movs r1, #10B ; Décallage du GPIO1 correspondant à la broche E de l'écran.
	str.n r1, [r3, #GPIO_OUT_CLR_Offset]

	push.n {r0}
	push.n {r1}
	bl delay ; Temps de l'instruction.
	pop.n {r1}
	pop.n {r0}
	str.n r1, [r3, #GPIO_OUT_SET_Offset]

	pop.n {r0, r1, r2, r3}
	pop.n {PC}

align 4

LCD:
	.GPIO_BASE DW 0x40014000
	.SIO_BASE DW 0xD0000000