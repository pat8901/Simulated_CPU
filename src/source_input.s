start:
	and R2,R3
	jal R4,mysub
retadr: and R3,R2
	jmp start
mysub:
	and R6,R8
	jmp *R4
