org 0

; Ce fichier sert pour booter depuis la XIP. Son but est de copier les données de la flash vers la SRAM
; Adresse 0x20000000. Pour une execution bien plus rapide.

; Dans la flash, il faudra mettre à l'adresse 0x100 la quantité d'octets à charger à partir de 0x104. En little endian.

; ID du RP2040 : 0xe48bff56

SSI_SSIENR_Offset equ 0x08
SSI_BAUDR_Offset equ 0x14
SSI_SER_Offset equ 0x10
SSI_IMR_Offset equ 0x2C
SSI_CTRLR0_Offset equ 0x00
SSI_DR0_Offset equ 0x60
SSI_RXFLR_Offset equ 0x24
SSI_SR_Offset equ 0x28
SSI_SPI_CTRLR0_Offset equ 0xF4
SSI_VERSION_ID_Offset equ 0x5C
SSI_DMACR_Offset equ 0x4C
SSI_RX_SAMPLE_DLY_Offset equ 0xF0

CODE16

Boot_Start:

	CPSID.N iflags_i  ; Je ne veux pas d'interruption. Je n'aime pas être interrompu !

	LDR.N R0, [reset] ; Permet de rendre accessible les périfériques en desactivant le reset.
	MOVS R1, #0
	STR.N R1, [R0, R1]

	; Lit les données depuis la flash et les copies sur la RAM.

	; Initialise les QSPI ainsi que les pads

	ldr.n r0, [GPIO_QSPI_BASE]
	adds r0, r0, #4
	movs r1, #6
	movs r2, #0 ; SSI

	qspiloop:
		str.n r2, [r0, #0]
		adds r0, r0, #8
		subs r1, r1, #1
		bne qspiloop

	ldr.n r0, [QSPI_PAD_BASE]
	adds r0, r0, #4 ; Pour passer le voltage select
	movs r1, #6
	movs r2, #01110001B

	qspipadloop:
		str.n r2, [r0, #0]
		adds r0, r0, #4
		subs r1, r1, #1
		bne qspipadloop

	;Désactive le ssi

	ldr.n r0, [SSI_BASE]
	movs r1, #0
	str.n r1, [r0, #SSI_SSIENR_Offset]

	;Initialise ctrl 0

	ldr.n r1, [SSI_CTRL_CONFIG]
	str.n r1, [r0, #SSI_CTRLR0_Offset]

	; Met le diviseur de clock à 4.
	movs r1, #4
	str.n r1, [r0, #SSI_BAUDR_Offset]

	; Masque toute les interruptions

	movs r1, #0xFF
	str.n r1, [r0, #SSI_IMR_Offset]

	; Définit un truc.
	movs r1, #1
	movs r4, #SSI_RX_SAMPLE_DLY_Offset
	str.n r1, [r0, r4]

	; Active le ssi

	movs r1, #1
	str.n r1, [r0, #SSI_SSIENR_Offset]

	;Sélectionne l'esclave
	movs r1, #1
	str.n r1, [r0, #SSI_SER_Offset]

	; Copie les octets de la flash vers la RAM

	movs.n R2, #0xFF ; Read Start Address
	adds R2, R2, #(1+3)

	; Récupère quatres octets pour la quantité d'octets à charger.

	movs r4, #0
	bl readFlashOrr
	bl readFlashOrr
	bl readFlashOrr
	bl readFlashOrr
	adds R2, R2, #(1+4) ; Le programme commence à 0x104 

	ldr.n R3, [destinationAddress]
	adds r4, #0xFF
	adds r4, #4

	copyLoop:
		bl readFlash
		strb.n r1, [r3, #0]
		adds r3, r3, #1
		adds r2, r2, #1
		cmp r2, r4
		bne copyLoop

Do:

	ldr.n r0, [destinationAddress]
	movs r1, #1
	orrs r0, r0, r1
	push.n {r0}
	pop.n {pc}

; Call readFlash, Shift R4 left 8. orrs the return value on R4
; Decrement R2 after flash call.

readFlashOrr:
	push.n {lr}
	bl readFlash
	lsls r4, r4, #8
	orrs r4, r4, r1
	subs r2, r2, #1
	pop.n {pc}


; Take address in R2, return value in r1

readFlash:
	push.n {lr}

	movs r1, #0x03 ; Read Command
	str.n r1, [r0, #SSI_DR0_Offset]

	movs r1, r2
	lsrs r1, r1, #16
	uxtb r1, r1 ; Filtre les 8 premiers bits.
	str.n r1, [r0, #SSI_DR0_Offset]

	movs r1, r2
	lsrs r1, r1, #8
	uxtb r1, r1 ; Filtre les 8 premiers bits.
	str.n r1, [r0, #SSI_DR0_Offset]

	movs r1, r2
	uxtb r1, r1 ; Filtre les 8 premiers bits.
	str.n r1, [r0, #SSI_DR0_Offset]

	movs r1, #0
	str.n r1, [r0, #SSI_DR0_Offset] ; Response.

	bl waitBusy

	ldr.n r1, [r0, #SSI_DR0_Offset]
	ldr.n r1, [r0, #SSI_DR0_Offset]
	ldr.n r1, [r0, #SSI_DR0_Offset]
	ldr.n r1, [r0, #SSI_DR0_Offset]
	ldr.n r1, [r0, #SSI_DR0_Offset] ; Cette ligne est LA ligne qui récupère la valeur de retour ( :)

	bl waitBusy

	pop.n {pc}

; Need R0 to be at SSI base Address value.
waitBusy:
	push.n {r1, r2}
	movs r2, #1
	; Wait for TFE one.
	.loop1:
		ldr.n r1, [r0, #SSI_SR_Offset]
		lsrs r1, r1, #2
		ands r1, r1, r2 ; Filter for TFE.
		beq .loop1

		; Wait for busy flag unset.
	.loop2:
		ldr.n r1, [r0, #SSI_SR_Offset]
		ands r1, r1, r2 ; Filter for BUSY.
		bne .loop2
	pop.n {r1, r2}
	bx lr

align 4 ; Alignement car ARM est ronchon avec les adresses non multiple de 4

destinationAddress: dw 0x20000000

testoff: dw 0x41C
gp25: dw 0x400140CC
confb: dw 0x331F
QSPI_PAD_BASE: DW 0x40020000
SSI_CTRL_CONFIG: DW 0x00070000 ;0x01470000
SSI_BASE: DW 0x18000000
GPIO_QSPI_BASE: DW 0x40018000
reset: DW 0x4000C000

times (252-($-Boot_Start)) db 0

dw 0 ; Checksum.