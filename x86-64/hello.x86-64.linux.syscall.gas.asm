
.globl _start
.section .text

_start:
	mov $1,%rax
	mov $1,%rdi
	mov message,%rsi
	mov $13,%rdx
	syscall

	mov $60,%rax
	xor %rdi,%rdi
	syscall

.section .rodata
message:
	.ascii "Hello world!\x0a"

