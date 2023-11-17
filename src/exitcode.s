	#Patrick Seitz
	.section .text
	.globl _start	#So the linker can see _start

_start:
	# %ebx is the staus code for the exit system call
	# so we put a number in it

	movl $2, %ebx
	movl $1, %eax		#1 is the exit() syscall
	int $0x80

