CODE16


; Convert un nombre 8 bits non signé en une chaine de caractères.
; Entrée : Valeur -> r0[7:0] Adresse du buffer de sortie -> r2
; Sortie : Buffer à l'adresse spécifiée dans r2. Ce buffer doit faire 3 caractères au moin.

byteDecString:
	push.n {lr}
	push.n {r0, r1}
	movs r1, #10
	uxtb r0, r0 ; Garde seulement les 8 premiers bits.

	push.n {r0}
	bl umod32
	adds r0, #0x30
	strb.n r0, [r2, #2]
	pop.n {r0}

	bl udiv32 ; Divise par 10 pour décaler les chiffres

	push.n {r0}
	bl umod32
	adds r0, #0x30
	strb.n r0, [r2, #1]
	pop.n {r0}

	bl udiv32 ; Divise par 10 pour décaler les chiffres
	
	push.n {r0}
	bl umod32
	adds r0, #0x30
	strb.n r0, [r2, #0]
	pop.n {r0}
	pop.n {r0, r1}
	pop.n {pc}

; Convert un nombre 16 bits non signé en une chaine de caractères.
; Entrée : Valeur -> r0[15:0] Adresse du buffer de sortie -> r2
; Sortie : Buffer à l'adresse spécifiée dans r2. Ce buffer doit faire 5 caractères au moin.

wordDecString:
	push.n {lr}
	push.n {r0, r1}
	movs r1, #10
	uxth r0, r0 ; Garde seulement les 16 premiers bits.

	push.n {r0}
	bl umod32
	adds r0, #0x30
	strb.n r0, [r2, #4]
	pop.n {r0}

	bl udiv32 ; Divise par 10 pour décaler les chiffres

	push.n {r0}
	bl umod32
	adds r0, #0x30
	strb.n r0, [r2, #3]
	pop.n {r0}

	bl udiv32 ; Divise par 10 pour décaler les chiffres
	
	push.n {r0}
	bl umod32
	adds r0, #0x30
	strb.n r0, [r2, #2]
	pop.n {r0}

	bl udiv32 ; Divise par 10 pour décaler les chiffres
	
	push.n {r0}
	bl umod32
	adds r0, #0x30
	strb.n r0, [r2, #1]
	pop.n {r0}

	bl udiv32 ; Divise par 10 pour décaler les chiffres
	
	push.n {r0}
	bl umod32
	adds r0, #0x30
	strb.n r0, [r2, #0]
	pop.n {r0}

	pop.n {r0, r1}
	pop.n {pc}

; Convert un nombre 32 bits non signé en une chaine de caractères.
; Entrée : Valeur -> r0[15:0] Adresse du buffer de sortie -> r2
; Sortie : Buffer à l'adresse spécifiée dans r2. Ce buffer doit faire 10 caractères au moin.

dWordDecString:
	push.n {lr}
	push.n {r0, r1}
	movs r1, #10

	push.n {r0}
	bl umod32
	adds r0, #0x30
	strb.n r0, [r2, #9]
	pop.n {r0}

	bl udiv32 ; Divise par 10 pour décaler les chiffres

	push.n {r0}
	bl umod32
	adds r0, #0x30
	strb.n r0, [r2, #8]
	pop.n {r0}

	bl udiv32 ; Divise par 10 pour décaler les chiffres
	
	push.n {r0}
	bl umod32
	adds r0, #0x30
	strb.n r0, [r2, #7]
	pop.n {r0}

	bl udiv32 ; Divise par 10 pour décaler les chiffres
	
	push.n {r0}
	bl umod32
	adds r0, #0x30
	strb.n r0, [r2, #6]
	pop.n {r0}

	bl udiv32 ; Divise par 10 pour décaler les chiffres
	
	push.n {r0}
	bl umod32
	adds r0, #0x30
	strb.n r0, [r2, #5]
	pop.n {r0}

	bl udiv32

	push.n {r0}
	bl umod32
	adds r0, #0x30
	strb.n r0, [r2, #4]
	pop.n {r0}

	bl udiv32 ; Divise par 10 pour décaler les chiffres

	push.n {r0}
	bl umod32
	adds r0, #0x30
	strb.n r0, [r2, #3]
	pop.n {r0}

	bl udiv32 ; Divise par 10 pour décaler les chiffres
	
	push.n {r0}
	bl umod32
	adds r0, #0x30
	strb.n r0, [r2, #2]
	pop.n {r0}

	bl udiv32 ; Divise par 10 pour décaler les chiffres
	
	push.n {r0}
	bl umod32
	adds r0, #0x30
	strb.n r0, [r2, #1]
	pop.n {r0}

	bl udiv32 ; Divise par 10 pour décaler les chiffres
	
	push.n {r0}
	bl umod32
	adds r0, #0x30
	strb.n r0, [r2, #0]
	pop.n {r0}

	pop.n {r0, r1}
	pop.n {pc}

; Converti un demi octet dans r0 en un caractère hexadecimal.
; Entrée : Valeur -> r0[3:0]
; Sortie : r1 <- Code ascii correspondant au caractère.

halfByteHexString:
	push.n {r0}
	movs r1, #0x0F
	ands r0, r0, r1 ; Récupère seulement les 4 premiers bits de r0.
	adds r0, #0x30  ; Rajoute 0x30 à la valeur pour qu'elle se transforme en chiffre.
	movs r1, 0x39
	cmp r0, r1  ; Plus grand que 0x39 ?
	bgt .add7   ; Alors ajouter 7 pour arriver sur les lettres.
	b .end
.add7:
	adds r0, #7
.end:
	movs r1, r0 ; Met la valeur de retour
	pop.n {r0}  ; Restore r0.
	bx lr

; Converti un octet dans r0, en une chaine de caractères hexadécimale.
; Entrée : Valeur -> r0[7:0] Adresse du buffer de sortie -> r2
; Sortie : Buffer à l'adresse spécifiée dans r2.

byteHexString:
	push.n {lr}
	push.n {r0}
	bl halfByteHexString
	strb.n r1, [r2, #1]
	lsrs r0, r0, #4
	bl halfByteHexString
	strb.n r1, [r2, #0]
	pop.n {r0}
	pop.n {pc}

; Converti un word (16 bits) dans r0, en une chaine de caractères hexadécimale.
; Entrée : Valeur -> r0[15:0] Adresse du buffer de sortie -> r2
; Sortie : Buffer à l'adresse spécifiée dans r2.

wordHexString:
	push.n {lr}
	push.n {r0}
	bl halfByteHexString
	strb.n r1, [r2, #3]
	lsrs r0, r0, #4
	bl halfByteHexString
	strb.n r1, [r2, #2]
	lsrs r0, r0, #4
	bl halfByteHexString
	strb.n r1, [r2, #1]
	lsrs r0, r0, #4
	bl halfByteHexString
	strb.n r1, [r2, #0]
	pop.n {r0}
	pop.n {pc}

; Converti un double word (32 bits) dans r0, en une chaine de caractères hexadécimale.
; Entrée : Valeur -> r0[31:0] Adresse du buffer de sortie -> r2
; Sortie : Buffer à l'adresse spécifiée dans r2.

dWordHexString:
	push.n {lr}
	push.n {r0}
	bl halfByteHexString
	strb.n r1, [r2, #7]
	lsrs r0, r0, #4
	bl halfByteHexString
	strb.n r1, [r2, #6]
	lsrs r0, r0, #4
	bl halfByteHexString
	strb.n r1, [r2, #5]
	lsrs r0, r0, #4
	bl halfByteHexString
	strb.n r1, [r2, #4]
	lsrs r0, r0, #4
	bl halfByteHexString
	strb.n r1, [r2, #3]
	lsrs r0, r0, #4
	bl halfByteHexString
	strb.n r1, [r2, #2]
	lsrs r0, r0, #4
	bl halfByteHexString
	strb.n r1, [r2, #1]
	lsrs r0, r0, #4
	bl halfByteHexString
	strb.n r1, [r2, #0]
	pop.n {r0}
	pop.n {pc}