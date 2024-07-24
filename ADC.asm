CODE16

; Démarre l'ADC et le capteur de température

ADC_Begin:
	push.n {r0, r1}
	ldr.n r0, [ADC_.base]
	movs r1, #11B
	str.n r1, [r0, #0] ; Offset du registre CS
	pop.n {r0, r1}
	bx lr


; Fais une mesure sur une entrée de l'ADC
; R0 <- Numéro du port ADC. (4 Pour capteur de température)
; La valeur de retour est dans R0

ADC_OneShotMesure:
	push.n {r1, r2}

	; Récupère la valeur du registre de controle pour la rétablir après la mesure.
	ldr.n r1, [ADC_.base]
	ldr.n r2, [r1]

	lsls r0, r0, #12 ; Décale le numéro de port ADC pour correspondre à l'offset.
	movs r1, #100B ; Décalage du bit "start once"
	orrs r0, r0, r1
	ldr.n r1, [ADC_.base_set]
	str.n r0, [r1, #0] ; Offset du registre CS

	; Maintenant attend que la mesure soit finie.
	movs r0, #1
.wait:
	ldr.n r1, [ADC_.base]
	ldr.n r1, [r1]
	lsrs r1, r1, #8 ; Décalage du bit ready
	ands r1, r1, r0
	beq .wait

	; Récupère la valeur.

	ldr.n r0, [ADC_.base]
	ldr.n r0, [r0, #4] ; Offset du result.

	; Restore la valeur du registre de controle

	ldr.n r1, [ADC_.base]
	str.n r2, [r1]

	pop.n {r1, r2}
	bx lr




; Un enderscore a été rajouté au label de ADC car "ADC" est un mot réservé.

ADC_:
	.base: dw 0x4004c000
	.base_set: dw 0x4004c000+0x2000
	.base_clear: dw 0x4004c000+0x3000