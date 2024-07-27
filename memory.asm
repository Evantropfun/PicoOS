CODE16

; Ce fichier contient les foncitons d'allocation dynamique du kernel.
; La mémoire, sera organisée comme une linked list.
; Chaques structure de la liste sera organisée comme suit :
; 
; Adresse de la structure précédente - 32 Bits, 0 si il s'agit du premier maillion.
; Adresse de la prochaine structure - 32 Bits, 0 si il s'agit du dernier maillion
; Drapeaux - 32 Bits, Bit 0 <- "Suis-je alloué ?"
; 
; Initialement il y aura un premier bloc mémoire qui occupera l'intégralité de la mémoire disponible et sera libre.
; Quand malloc sera appelé, la fonction ira chercher le premier bloc disponible, si celui ci a la taille voulue, alors réserver ce bloc, sinon si celui ci est plus grand que la taille voulue, alors diviser le bloc. Si trop petit, aller voir le bloc suivant.
; Ce fichier contiendra aussi des fonctions destinées à des usages générals, comme lire et écrire des données à des adresses NON alignées.

; Coupe un bloc mémoire
; r0 <- Adresse du bloc
; r1 <- Taille du bloc à couper
; Cette fonction ne fait aucune vérification sur la taille du bloc initiale.

memory_cut:
	push.n {r0, r1, r2}
	; Récupère l'adresse de la structure suivant le bloc.
	ldr.n r2, [r0, #4]

	; Calcule l'adresse de la nouvelle structure dans r1.
	adds r1, r1, r0
	adds r1, #12 ; Ajoute l'header.

	; Ecrit cette nouvelle adresse dans le premier bloc
	str.n r1, [r0, #4] ;

	; Ecrit l'adresse précédente du bloc qui viens après le bloc à diviser.
	orrs r2, r2, r2
	beq .skip ; Si r2 vaut 0 alors pas besoin de le faire.
	str.n r1, [r2, #0]
.skip:

	; Initialise la structure du deuxième bloc né du découpage.
	str.n r0, [r1] ; Ecrit l'adresse précédente
	str.n r2, [r1, #4] ; Ecrit l'adresse suivante
	movs r2, #0 ; R2 n'est plus nécéssaire maintenant.
	str.n r2, [r1, #8] ; Met le flag à "Je ne suis pas alloué"

	; Voilà, le bloc est coupé maintenant.
	pop.n {r0, r1, r2}
	bx lr

; Alloue un bloc mémoire.
; r0 <- Taille du bloc voulu.
; L'adresse du bloc est retourné dans r0.

memory_alloc:
	push.n {lr}
	push.n {r1, r2}
	; Récupère l'adresse de le mémoire, ou plutot, du premier bloc de la liste.
	ldr.n r1, [memory.addr]

	; Maintenant on va chercher un bloc libre.
.searchloop:
	ldr.n r2, [r1, #8] ; regarde le flag
	orrs r2, r2, r2
	beq .next ; N'est pas alloué ? Alors passons à la suite.
.tooTiny: ; Si le bloc trouvé se révelait trop petit, reviens ici

	; Sinon on va voir le bloc suivant.
	ldr.n r1, [r1, #4]
	b .searchloop
.next:

	; On a trouvé un bloc libre ! 
	; Mais est il trop petit ?
	ldr.n r2, [r1, #4] ; Récupère l'adresse du prochain.
	orrs r2, r2, r2
	beq .tooBig ; Dernier maillion ? Alors forcément trop gros.
	subs r2, r2, r1 ; Enlève l'adresse du bloc courant pour obtenir la taille du bloc + la taille de l'header.
	subs r2, #12 ; Enlève la taille de l'header.
	cmp r2, r0
	beq .allocate; Ils font la meme taille ? Alors allouer ce bloc.
	bls .tooTiny ; Bloc trop petit, au suivant !
.tooBig:

	; Par déduction, si on arrive à ce point là du code, ça signifie que le bloc est plus grand que celui voulu. Alors on va le couper.

	push.n {r0} ; interverti r0, et r1
	movs r0, r1
	pop.n {r1}
	bl memory_cut ; R0 = addr R1 = Taille
	push.n {r0} ; Réinterverti r0, et r1
	movs r0, r1
	pop.n {r1}

.allocate:
	; Ici r1 contient l'adresse du bloc à allouer qui fait *normalement* la bonne taille.

	movs r2, #1
	str.n r2, [r1, #8] ; Met le flag à "alloué"
	movs r0, r1
	adds r0, #24
	pop.n {r1, r2}
	pop.n {pc} ; return.

memory:
	align 4
	.addr: dw dynamicAllocationSpace

; Lit un mot de 32 bits à une adresse, peut importe si celle ci est alignée ou non.

; R0 <- Adresse du mot
; Valeur retournée dans r0.

memory_readDWord:

	push.n {r1, r2}

	movs r2, r0 ; Met adresse dans R2
	movs r0, #0 ; Met 0 dans r0

	ldrb.n r1, [r2]
	orrs r0, r0, r1

	ldrb.n r1, [r2, #1]
	lsls r1, r1, #8
	orrs r0, r0, r1

	ldrb.n r1, [r2, #2]
	lsls r1, r1, #16
	orrs r0, r0, r1

	ldrb.n r1, [r2, #3]
	lsls r1, r1, #24
	orrs r0, r0, r1

	pop.n {r1, r2}
	bx lr

; Lit un mot de 16 bits à une adresse, peut importe si celle ci est alignée ou non.

; R0 <- Adresse du mot
; Valeur retournée dans r0.

memory_readWord:
	push.n {r1, r2}

	movs r2, r0 ; Met adresse dans R2
	movs r0, #0 ; Met 0 dans r0

	ldrb.n r1, [r2]
	orrs r0, r0, r1

	ldrb.n r1, [r2, #1]
	lsls r1, r1, #8
	orrs r0, r0, r1

	pop.n {r1, r2}
	bx lr

; Copie une région mémoire de taille R2 de l'adresse R0, à l'adresse R1.

;R0 <- Région source
;R1 <- Région destination
;R2 <- Taille à copier.

memory_copy:
	push.n {r0, r1, r2, r3}
.loop:
	ldrb.n r3, [r0] ; Tellement simple que y'a pas besoin d'expliquer
	strb.n r3, [r1]
	adds r0, #1
	adds r1, #1
	subs r2, r2, #1
	bne .loop
	pop.n {r0, r1, r2, r3}
	bx lr

; Compare deux régions mémoire de même taille.
; R0 <- Adresse de la région 1
; R1 <- Adresse de la région 2
; R2 <- Taille des régions.
; Si les deux régions sont strictement identiques, alors R0 se verra attribuer la valeur 1, sinon 0.

memory_compare:
	push.n {r1, r2, r3, r4}
.loop:
	ldrb.n r3, [r0] ; Récupère les deux octets correspondants des deux régions.
	ldrb.n r4, [r1]
	cmp r3, r4
	bne .notEqual ; N'est pas égal ? Retourne 0.
	adds r0, #1
	adds r1, #1
	subs r2, r2, #1
	bne .loop
; Est égal ? retourne 1.
	movs r0, #1
	pop.n {r1, r2, r3, r4}
	bx lr
.notEqual:
	movs r0, #0
	pop.n {r1, r2, r3, r4}
	bx lr