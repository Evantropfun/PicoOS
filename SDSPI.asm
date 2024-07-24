; Ce fichier contient le code chargé de controller une carte SD sur bus SPI

CODE16

; Initialise la carte SD sur le SPI0 par def
; Sur les pins 16, 17, 18, 19
; s'occupe de tout, assignement des pins, initialisation du controlleur SPI, tout, tout.

SDSPI_InitSDCardDefaultConfig:
	push.n {lr}
	push.n {r0, r1, r2, r3, r4}

	; Initialise le SPI pour la carte SD

	movs r0, #0 ; SPI0
	movs r1, #2 
	movs r2, #200 ; 200*2 = 400 de diviseur
	movs r3, #8 ; 8 bits par commandes
	bl SPI_Init

	; Setup les GPIO

	movs r1, #GPIO_SPI
	movs r0, #16
	bl GPIO_Connect
	movs r0, #18
	bl GPIO_Connect

	movs r0, #17        ; Met CS et MOSI à 1 pour les 10 envois d'initialisation de la SD
	bl GPIO_PutHigh
	movs r0, #19
	bl GPIO_PutHigh

	movs r0, #0

	bl SPI_SendData
	bl SPI_SendData
	bl SPI_SendData
	bl SPI_SendData
	bl SPI_SendData
	bl SPI_SendData
	bl SPI_SendData
	bl SPI_SendData
	bl SPI_SendData
	bl SPI_SendData

	; Setup les GPIO

	movs r1, #GPIO_SPI
	movs r0, #17
	bl GPIO_Connect
	movs r0, #19
	bl GPIO_Connect

	movs r0, #0 ; Controlleur SPI0
	movs r1, #0 ; CMD0
	movs r2, #0 ; Aucun argument.
	movs r3, #1001010B ; Le CRC.
	bl SDSPI_SendCommand
	bl SDSPI_WaitForResponseR1

	movs r0, #0 ; Controlleur SPI0
	movs r1, #8 ; CMD8
	ldr.n r2, [.CMD8_ARG]
	movs r3, #1001010B ; Le CRC.
	bl SDSPI_SendCommand
	bl SDSPI_WaitForResponseR7

	.initwait:
	movs r0, #0 ; Controlleur SPI0
	movs r1, #55 ; CMD55 ; Prochaine commande est une app-specific
	movs r2, #0 ; Aucun argument.
	movs r3, #1001010B ; Le CRC.
	bl SDSPI_SendCommand
	bl SDSPI_WaitForResponseR1

	movs r0, #0 ; Controlleur SPI0
	movs r1, #41 ; ACMD41 ; Lance processus d'initialisation.
	movs r2, #1
	lsls r2, r2, #30
	movs r3, #1001010B ; Le CRC.
	bl SDSPI_SendCommand
	bl SDSPI_WaitForResponseR1
	cmp r0, #1
	beq .initwait

	pop.n {r0, r1, r2, r3, r4}
	pop.n {pc}

align 4
.CMD8_ARG: DW (0001B shl 8) or (0xAB)

; Lit un bloc de 512 octets à une adresse spécifique.
; R0 <- Controlleur SPI où est branché et initialisé la carte.
; R1 <- Adresse physique où stocker les données reçue.
; R2 <- Adresse LBA où lire les données. (LBA = Numéro de bloc, commence avec 0.)
; Ne vérifie pas encore les erreurs.

SDSPI_ReadBlock:
	push.n {lr}
	push.n {r1, r2, r3}
	; Garde R1 car il sera altéré.

	movs r3, r1

	; Envoit la requête de lecture. 
	
	movs r1, #17 ; CMD17 Read Single Block
	bl SDSPI_SendCommand
	bl SDSPI_WaitForResponseR1 ; On partira du principe qu'il n'y a aucun problèmes.

	; Attend le token de départ.
.wwwait:
	movs r1, #0xFF
	bl SPI_SendData
	cmp r1, #0xFF
	beq .wwwait

	; Dump le bloc et le stocke à l'adresse spécifiée.
	movs r2, #0xFF
	adds r2, #0xFF ; 255 + 255 + 2 = 512
	adds r2, #2
.loop:
	movs r1, #0xFF
	bl SPI_SendData
	strb.n r1, [r3]
	adds r3, r3, #1
	subs r2, r2, #1
	bne .loop

	; Retire les deux octets de CRC. On s'en fout du CRC, c'est nul.
	movs r1, #0xFF
	bl SPI_SendData
	movs r1, #0xFF
	bl SPI_SendData

	pop.n {r1, r2, r3}
	pop.n {PC}



; Envoit une commande à la carte SD.
; R0 <- Numéro du controlleur SPI
; R1 <- Numéro de commande
; R2 <- Argument si nécéssaire.
; R3 <- Code CRC si nécéssaire.

SDSPI_SendCommand:
	push.n {lr}
	push.n {r1}

	adds.n r1, #01000000B ; Rajoute le code de début de paquet
	bl SPI_SendData
	; Envoit chaque octets de l'argument.

	movs r1, r2
	lsrs r1, r1, #24
	bl SPI_SendData
	movs r1, r2
	lsrs r1, r1, #16
	bl SPI_SendData
	movs r1, r2
	lsrs r1, r1, #8
	bl SPI_SendData
	movs r1, r2
	bl SPI_SendData
	; Envoit le crc

	movs r1, r3
	lsls r1, r1, #1
	adds r1, #1
	bl SPI_SendData

	pop.n {r1}
	pop.n {PC}

; Attend pour une réponse.
; L'interprettera comme un réponse de type R7
; R0 <- Controlleur SPI
; La partie R1 de la réponse R7 sera mise dans r0.
; Les quatres octets suivants de la réponses seront dans r1.

SDSPI_WaitForResponseR7:
	push.n {lr}
.wait:
	movs r1, #0xFF
	bl SPI_SendData
	cmp r1, #0xFF
	beq .wait

	bl SDSPI_SampleReceivedData
	push.n {r1}

	movs r0, #0

	bl SDSPI_SampleReceivedDataNext
	lsls r1, r1, #24
	orrs r0, r0, r1
	bl SDSPI_SampleReceivedDataNext
	lsls r1, r1, #16
	orrs r0, r0, r1
	bl SDSPI_SampleReceivedDataNext
	lsls r1, r1, #8
	orrs r0, r0, r1
	bl SDSPI_SampleReceivedDataNext
	orrs r0, r0, r1
	movs r1, r0

	pop.n {r0}
	pop.n {PC}

; Attend pour une réponse.
; L'interprettera comme un réponse de type R1
; R0 <- Controlleur SPI
; Réponse est retournée dans R0.

SDSPI_WaitForResponseR1:
	push.n {lr}
	push.n {r1, r2, r3, r4}

.wait:
	movs r1, #0xFF
	bl SPI_SendData
	cmp r1, #0xFF
	beq .wait

	bl SDSPI_SampleReceivedData
	movs r0, r1

	pop.n {r1, r2, r3, r4}
	pop.n {PC}


; Récupère correctement un octet (Mais pas que.)
; r1 <- premier octet reçu ne valant pas 0xFF

; Ce qui suit son des infos retournées

; r2 <- Valeur initiale du deuxième octet reçu ( Si r3 == 0 alors le deuxième octet n'a pas été demandé à la carte. Mais cela signifie que le deuxième octet sera aligné à l'octet. )
; r3 <- Nombre de décalage effectué
; r4 <- 8 - Nombre de décalage effectué 
; La réponse R1 est stockée dans le registre r1.
; La fonction est conçu pour être utilisée en chaine afin de recevoir les autres formats de réponses.
; Alors la fonction altere aussi R2 et R3 pour fournir des infos importantes.

SDSPI_SampleReceivedData:
	push.n {lr}
	push.n {r0}
	movs r3, #0
	movs r4, #8
	movs r0, r1 ; Copie r0 dans r1 pour voir si le bit 7 vaut 0.
	lsrs r0, r0, #7
	beq .end ; Vaut 0 ? Alors très bien. Sinon traitement à faire.

	movs r2, #0 ; Registre pour compter le nombre d'itération de la boucle
.loop: ; Va shifter vers la gauche r1, jusqu'à que son bit 7 vale 0.
	lsls r1, r1, #1 ; Décale 1 bit sur la gauche
	uxtb r1, r1
	adds r2, r2, #1 ; Ajoute 1 au compteur.
	movs r0, r1 ; Copie r0 dans r1 pour voir si le bit 7 vaut 0.
	lsrs r0, r0, #7
	cmp r0, #0
	bne .loop ; Sinon on itère encore.

	push.n {r2} ; Push le nombre de décalage effectué pour le retourner à la fin.

	; Récupère les bits manquant au près de la gentille carte SD.

	push.n {r1}
	movs r0, #0
	movs r1, #0xFF
	bl SPI_SendData
	movs r3, r1 ; Sauvegarde la valeur récupérée dans r3.
	pop.n {r1}

	push.n {r3} ; Pour retourner à la fin la deuxième valeur

	; Calcul dans r2 la quantité de bit qu'il faudra shifter.

	movs r0, #8
	subs r2, r0, r2

	; Applique le shift sur la nouvelle valeur récupérée dans r3.
	lsrs r3, r3, r2
	orrs r1, r1, r3 ; Fais l'opération ou pour obtenir la valeur finale.

	movs r4, r0 ; Récupère 8 - Nombre de décalage effectué 
	pop.n {r2} ; Récupère valeur initiale du deuxième octet
	pop.n {r3} ; Récupère le nombre de décalage effectué

.end:
	pop.n {r0}
	pop.n {pc}

; Fonction qui va avec celle juste au dessus
; Prend en entré toute les informations que sort SDSPI_SampleReceivedData, dans les memes registres.
; Valeur de retour dans r1.
; retour : r2 <- Valeur initiale du nouvel octet demandé, s'il a été demandé.

SDSPI_SampleReceivedDataNext:
	push.n {lr}
	push.n {r0}

	; Prend juste l'octet qui viens. Il est déjà aligné alors rien à faire.
	movs r0, #0
	movs r1, #0xFF
	bl SPI_SendData
	push.n {r1}

	cmp r3, #0
	bne .doTheHardWork ; Pas aligné, alors il faut faire le travail difficile.

	pop.n {r1}
	pop.n {r0}
	pop.n {pc}
.doTheHardWork:
	; La travaille difficile.

	movs r1, r2
	lsls r1, r1, r3 ; Premier shift

	pop.n {r2} ; Récupère la valeur reçu.
	movs r0, r2

	lsrs r0, r0, r4
	orrs r1, r1, r0 ; Obtient la valeur finale

	pop.n {r0}
	pop.n {pc}
