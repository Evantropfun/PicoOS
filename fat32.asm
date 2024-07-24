

; Ce fichier contient les fonctions en lien avec le support de fat32.
; Le dispositif de stockage choisi doit avoir une table de partition MBR
; Le système de fichier doit être sur l'entrée 0.

; Fonction pour lire un bloc sur le dispositif de stockage.

; R1 <- Adresse physique où stocker les données reçue.
; R2 <- Adresse LBA où lire les données. (LBA = Numéro de bloc, commence avec 0.)

fat32_readBlock:
	 ; pour l'instant tout sera récupéré sur la carte SD controlleur SPI 0.
	 push.n {lr}
	 push.n {r0}
	 movs r0, #0
	 bl SDSPI_ReadBlock
	 pop.n {r0}
	 pop.n {pc}

; Initialise la lib.

fat32_Init:
	push.n {lr}
	push.n {r0, r1, r2, r3, r4, r5}
	; Récupère l'adresse LBA de la première partition

	;Commence par charger le premier secteur du périférique.
	ldr.n r1, [fat32.temp_sector_addr]
	movs r2, #0
	bl fat32_readBlock

	; Récupère l'offset

	ldr.n r0, [.first_partition_lba_offset] 

	; Puis lis la valeur et la stocke

	adds r0, r0, r1 ; Converti en adresse physique.
	bl memory_readDWord ; L'adresse ne sera jamais alignée ici.
	ldr.n r1, [fat32.partition_lba_addr]
	str.n r0, [r1] ; Voilà ( R0 contient l'adresse LBA )

	; Maintenant récupère le premier secteur de la partition, et récupère des informations essentielles.

	ldr.n r1, [fat32.temp_sector_addr]
	movs r2, r0 ; Adresse LBA est normalement dans R0.
	bl fat32_readBlock ; Lit le bloc.

	; Récupère le nombre de secteur par cluster

	movs r0, r1 ; là r1 contient l'adresse du temp sector, je m'en sers directement.
	ldrb.n r0, [r0, #13]
	ldr.n r1, [fat32.sector_per_cluster_addr] ; Charge l'adresse pour 
	str.n r0, [r1] ; stocker la valeur

	; Récupère le nombre de secteurs réservés.

	ldr.n r0, [fat32.temp_sector_addr]
	ldrh.n r0, [r0, #14] ; L'adresse est alignée. Offset 14.
	ldr.n r1, [fat32.reserved_sectors_addr] ; Charge l'adresse pour 
	str.n r0, [r1] ; stocker la valeur

	; Récupère le nombre de secteurs par FAT.

	ldr.n r0, [fat32.temp_sector_addr]
	adds r0, #36
	ldr.n r0, [r0, #0]
	ldr.n r1, [fat32.sector_per_FAT_addr] ; Charge l'adresse pour 
	str.n r0, [r1] ; stocker la valeur

	ldr.n r0, [fat32.root_dir_cluster] ; récupère l'adresse LBA du cluster racine.
	bl fat32_ClusterToLBA

	; Maintenant lis le dossier racine

	movs r2, r0
	ldr.n r1, [fat32.temp_sector_addr]
	bl fat32_readBlock

	pop.n {r0, r1, r2, r3, r4, r5}
	pop.n {pc}
align 4
.first_partition_lba_offset: dw 0x1BE+0x08 ; Offset de l'adresse LBA de la partition.

fat32_Debug:
	ldr.n r0, [fat32.temp_sector_addr]
	bx lr

; Converti un numéro de cluster en numéro de secteur LBA.
; Formule : (Numéro de cluster - 2) * Secteur par cluster
;           + partition LBA
;           + secteurs réservés
;           + secteurs par FAT * 2
; r0 <- Numéro du cluster
; Valeur de retour dans r0.

fat32_ClusterToLBA:
	push.n {r1}
	subs r0, r0, #2
	ldr.n r1, [fat32.sector_per_cluster]
	muls r0, r1
	ldr.n r1, [fat32.partition_lba]
	adds r0, r0, r1
	ldr.n r1, [fat32.reserved_sectors]
	adds r0, r0, r1
	ldr.n r1, [fat32.sector_per_FAT]
	adds r0, r0, r1
	adds r0, r0, r1; Fois 2
	pop.n {r1}
	bx lr

; Lit un secteur et le stock dans le temp sector
; R0 <- Adresse LBA.

fat32_GetSectorInTempSector:
	push.n {lr}
	push.n {r1, r2}
	movs r2, r0
	ldr.n r1, [fat32.temp_sector_addr]
	bl fat32_readBlock
	pop.n {r1, r2}
	pop.n {pc}

; Charge le premier secteur du cluster choisi dans temp sector,
; en mettant à jour les valeurs associées.
; r0 <- Indexe du clusteur.

fat32_BeginClusterReading:
	push.n {lr}
	push.n {r0, r1, r2, r3}

	movs r3, r0 ; Garde précieusement le numéro de cluster.
	bl fat32_ClusterToLBA
	bl fat32_GetSectorInTempSector

	; r0 contient le LBA du cluster, r3 le numéro du cluster.
	ldr.n r1, [fat32.current_loaded_sector_addr]
	str.n r0, [r1, #4] ; Adresse LBA
	movs r0, #0
	str.n r0, [r1, #0] ; Adresse par apport au début, donc 0.

	ldr.n r1, [fat32.current_loaded_cluster_addr]
	str.n r3, [r1]

	pop.n {r0, r1, r2, r3}
	pop.n {pc}



; Cherche dans dans le temp sector des entrées de fichier.
; Esquive les Long File Name.
; R0 <- Position de la tete de lecture. (Offset par apport à l'adresse du temp sector)
; Retourne dans r1 l'adresse physique de l'entré d'un fichier ou d'un dossier.
; Retourne 0 dans r1 si arrivé à la fin.
; Retourne dans r0 la position de la tête de lecture.

fat32_SeekForData:
	push.n {lr}
	push.n {r2}
.loop:
	; Converti la tete de lecture en adresse physique.
	ldr.n r1, [fat32.temp_sector_addr]
	adds r1, r1, r0

	; Regarde si l'entrée est existante. Sinon, on est à la fin du dossier.
	ldrb.n r2, [r1, #0]
	cmp r2, #0
	beq .EndOfFolder

	cmp r2, #0xE5 ; Entrée supprimée ? On passe au suivant.
	beq .next

	; Regarde si l'entrée est une LFN
	ldrb.n r2, [r1, #0x0B] ; Offset de l'attribut.

	cmp r2, 0x0F
	bne .notLFN
	; C'est un LFN, on passe au suivant.
.next:
	adds r0, #32 ; Avance la tête de lecture.
	b .loop

.notLFN: ; Pas un LFN ? On peut renvoyer cette entré là.
	adds r0, #32 ; Avance la tete de lecture pour que le prochaine appel passe au suivant.
	pop.n {r2}
	pop.n {PC}

.EndOfFolder:
	movs r1, #0 ; Fin.
	pop.n {r2}
	pop.n {PC}

; Récupère le secteur suivant dans un fichier ou un dossier.
; Stocke tout dans temp sector

fat32_getNextSector:
	push.n {lr}
	push.n {r0, r1, r2}
	ldr.n r1, [fat32.current_loaded_sector_addr]

	ldr.n r2, [r1, #0]
	adds r2, #1
	str.n r2, [r1, #0]

	ldr.n r2, [r1, #4]
	adds r2, #1
	str.n r2, [r1, #4]

	movs r0, r2
	bl fat32_GetSectorInTempSector
	pop.n {r0, r1, r2}
	pop.n {pc}



; Retour l'adresse du temp sector dans r1

fat32_getTempSector:
	ldr.n r1, [fat32.temp_sector_addr]
	bx lr

fat32:
align 4
	.root_dir_cluster: dw 2
	.sector_per_FAT_addr: dw .sector_per_FAT
	.sector_per_FAT: dw 0
	.reserved_sectors_addr: dw .reserved_sectors
	.reserved_sectors: dw 0
	.sector_per_cluster_addr: dw .sector_per_cluster
	.sector_per_cluster: dw 0
	.partition_lba_addr: dw .partition_lba
	.partition_lba: dw 0 ; Adresse LBA de la partition sur laquelle est le système de fichier

	.current_loaded_sector_addr: dw .current_loaded_sector
	.current_loaded_sector: dw 0 ; Le secteur chargé dans temp sector, par apport au début du cluster.
	                        dw 0 ; Le secteur chargé dans temp sector, adresse LBA.
	.current_loaded_cluster_addr dw .current_loaded_cluster
	.current_loaded_cluster: dw 0 ; Le numéro du cluster activement chargé dans temp sector.
	.temp_sector_addr: dw .temp_sector
	.temp_sector: times 512 db 0