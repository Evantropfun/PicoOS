
; Ce code d'exemple dans le kernel lance un programme qui fait clignoter la LED built-in de la carte sur le deuxième coeur.
; Le coeur principale va lister et afficher tous les fichiers et dossiers à la racine de la carte SD.

file "bootFlash.bin"
dw (CODE_END-CODE_START+1) ; The second stage load this double word first, to know how many bytes to loads at 0x20000000.
;10001001
org 0x20000000

include "GPIODef.asm"

;python uf2conv.py kernel.bin --base 0x10000000 --family RP2040 --convert --output picoos.uf2
;python uf2conv.py kernel.bin --base 0x20000000 --family RP2040 --convert --output picoos.uf2
;Le kernel doit supporter par défaut un affichage LCD 16x4. ALors il initialise les GPIO 0 - 9 inclu.
;GP0 -> RS
;GP1 -> E
;GP2-9 -> D0-7
;RW est toujours à 0.

ROSC_DIV_Offset equ 0x10
ROSC_FREQB_Offset equ 0x08
GPIO_HI_OE_CLR_Offset equ 0x48
GPIO_HI_IN equ 0x08

SPI_SSPDR_Offset equ 0x08

; Startup delay value : 47

CODE16

CODE_START:

include "vector_table.asm"
SPEED equ 5

start:
	CPSID.N iflags_i 


	LDR.N R0, [reset] ; Permet de rendre accessible les périfériques en desactivant le reset.
	MOVS R1, #0
	STR.N R1, [R0, R1]

	ldr.n r0, [kernel_stack_base]
	ldr.n r1, [vector_table_addr]
	str.n r0, [r1, #0]
	msr msp, r0

	bl XOSC_Init ; On veut une clock qui va VITE
	bl LCD_InitGraphicMode
	bl CLOCK_SwitchCLKREFonXOSC ; Bien sur il faut switcher le CPU sur cette clock.
	bl CLOCK_StartCLKPERI       ; Les périfériques ne risquent pas de fonctionner sans le clock de périférique.

	ldr.n r0, [vtor_addr]
	ldr.n r1, [vector_table_addr]
	str.n r1, [r0, #0]

	bl PLL_InitUSB
	bl PLL_InitSys

	bl CLOCK_SwitchCLKSYSonPLL
	bl CLOCK_SwitchCLKADConPLL

	bl ADC_Begin
	bl systick_init
	CPSIE.N iflags_i 

	; Lance le programme du coeur 1 sur le coeur 1.

	ldr.n r1, [vector_table_addr]
	movs r0, #0xFF
	adds r0, #0xFF
	adds r0, #2
	bl memory_alloc ; Alloue une stack.
	movs r2, r0
	adds r2, #0xFF
	adds r2, #0xF0
	ldr.n r3, [core1_code_addr]
	bl core1_startcode

	bl SDSPI_InitSDCardDefaultConfig

	bl fat32_Init

	bl LCD_Clear

	ldr.n r4, [bootmsg.addr]
	svc #0

	; Cherche le fichier BOOT.BIN

	movs r0, #2 ; Cluster du dossier racine
	bl fat32_BeginClusterReading

	movs r0, #0
	push.n {r0}

searchloop:
	pop.n {r0}
	bl fat32_SeekForData
	cmp r1, #0
	beq kernel_finish

	push.n {r0}
	ldr.n r0, [bootfilestr.addr]
	movs r2, #8+3
	bl memory_compare
	cmp r0, #1
	bne searchloop
	pop.n {r0}

; Si on arrive ici, alors on a trouvé le fichier de boot. Adresse de l'entré dans r1.

	ldr.n r4, [foundmsg.addr]
	svc #0 ; STDOUT

	; Alloue 512 octets.

	movs r0, #0xFF
	adds r0, #0xFF
	adds r0, #2
	movs r2, r0
	bl memory_alloc
	push.n {r0}

	adds r1, #0x1A ; Offset numéro du cluster.
	ldrh r0, [r1, #0]
	pop.n {r1} ; L'adresse du programme est dans la stack.
	; r2 content déjà 512.
	bl fat32_loadFileWithClusterIndex

	bl execute_bootfile



kernel_finish:
	ldr.n r4, [haltmsg.addr]
	svc #0 ; STDOUT

kernel_end:
	CPSID.N iflags_i 
	wfi ; Halt the core 0
	b kernel_end

execute_bootfile:
	push.n {lr}
	movs r0, #1
	movs r6, r1 ; Le programme a besoin de ça !
	orrs r1, r1, r0
	bx r1

align 4

read_addr: dw 0;8192

core1_code_addr: dw (core1_code or 1)
CLK_GPOUT0_CTRL: dw 0x40008000
CLK_GPOUT0_CTRL_Config: dw (3 shl 5) or (1 shl 11)
CLK_GPOUT0_DIV: dw 0x40008004
CLK_GPOUT0_DIV_Config: dw 0xFFFFFFFF
variable: dw 0
vector_table_addr: dw vector_table
vtor_addr: dw 0xe000ed08
value: dw 0

num: db "00", 0
	align 4
	.addr: dw num

num32: db "0000000000", 0
	align 4
	.addr: dw num32

bootfilestr: db "BOOT    BIN",0
align 4
	.addr dw bootfilestr

haltmsg: db "[Kernel] Core 0 halted.", 10,0
align 4
	.addr dw haltmsg

svcmsg: db "Hello with SVC 0 !",10,"UwU",10,0
align 4
	.addr dw svcmsg

bootmsg: db "Pico OS v1.0.0",10,"Booting...",10,10,10, 0
	align 4
	.addr dw bootmsg

foundmsg: db "Boot file found.",10, 0
	align 4
	.addr dw foundmsg

align 4


reset: DW 0x4000C000
kernel_stack_base: dw (0x20040000)

align 4
include "SPI.asm"
align 4
include "clock.asm"
align 4
include "XOSC.asm"
align 4
include "StringConvertion.asm"
align 4
include "divider.asm"
align 4
include "GPIO.asm"
align 4
include "parallelLCD128X64.asm"
align 4
include "delay.asm"
align 4
include "bootscreen.asm"
align 4
include "PLL.asm"
align 4
include "ADC.asm"
align 4
include "cpufifo.asm"
align 4
include "systick.asm"
align 4
include "SDSPI.asm"
align 4
include "constantes.asm"
align 4
include "fat32.asm"
align 4
include "syscalls.asm"
align 4


include "interrupt.asm"

align 4
include "core1.asm"
align 4



include "memory.asm"

align 4

dynamicAllocationSpace:

; Structure de base pour l'allocation dynamique mémoire.

dw 0 ; Premier maillon donc 0
dw 0 ; Dernier maillon donc 0
dw 0 ; Non alloué, donc 0.

CODE_END: