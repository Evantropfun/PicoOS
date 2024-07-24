vector_table:
	b.n start
	b.n start
	.reset: dw (none_int or 1)
	.NMI: dw (none_int or 1)
	.HardFault: dw (none_int or 1)
	.reserved: times (7) dw 0
	.SVCall: dw (none_int or 1)
	.reserved2: times (2) dw 0
	.PendSV: dw (none_int or 1)
	.SysTick: dw (systick_interrupt or 1)
	times 32 dw (none_int or 1)