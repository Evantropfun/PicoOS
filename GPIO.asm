CODE16

; Ce fichier contient les fonctions en rapport avec les GPIO
; Controle des pads, des gpio, des status...

; Relis un GPIO à une fonction.
; R0 <- Numéro du GPIO
; R1 <- Identifiant de la fonction. Défini par le GPIO Muxing, "RP2040 Datasheet - 2.19.2"
; Si une fonction invalide est assignée à un pin, aucune erreur ne sera retournée.

GPIO_Connect:
	push.n {r0, r1, r2}
	movs r2, #11111B ; Filtre les 5 premiers bits de R1
	ands r1, r1, r2
	movs r2, #8
	muls r0, r0, r2 ; Multiplie R0 par 4 car les registres GPIO sont sur 4 octets.
	adds r0, r0, #4 ; S'alligne avec le registre de control.
	ldr.n r2, [GPIO.IO_BANK0_BASE]
	str.n r1, [r2, r0]
	pop.n {r0, r1, r2}
	bx lr

; Déconnecte le GPIO de tout périférique et le force à un état haut.
; R0 <- Numéro du GPIO

GPIO_PutHigh:
	push.n {r0, r1, r2}
	movs r1, #8
	muls r0, r0, r1 ; Multiplie R0 par 8 car les registres GPIO sont sur 4 octets.
	adds r0, r0, #4 ; S'alligne avec le registre de control.
	ldr.n r1, [.const]
	ldr.n r2, [GPIO.IO_BANK0_BASE]
	adds r2, r2, r0
	str.n r1, [r2]
	pop.n {r0, r1, r2}
	bx lr
	align 4
.const: dw 0x331F

; Déconnecte le GPIO de tout périférique et le force à un état bas.
; R0 <- Numéro du GPIO

GPIO_PutLow:
	push.n {r0, r1, r2}
	movs r1, #8
	muls r0, r0, r1 ; Multiplie R0 par 8 car les registres GPIO sont sur 4 octets.
	adds r0, r0, #4 ; S'alligne avec le registre de control.
	ldr.n r1, [.const]
	ldr.n r2, [GPIO.IO_BANK0_BASE]
	adds r2, r2, r0
	str.n r1, [r2]
	pop.n {r0, r1, r2}
	bx lr
	align 4
.const: dw 0x321F


align 4
GPIO:
	.IO_BANK0_BASE dw 0x40014000