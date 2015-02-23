/*
Output "Hello world!" to standard output.
For PowerPC 64-bit architecture with GNU assembler, using Linux syscalls.

Assemble with :
as -o hello.o hello.ppc64.linux.syscall.gas.asm &&
ld -o hello hello.o
*/

.data
message:
	.ascii "Hello world!\n"

len = . - message

.text
.global _start
.section ".opd", "aw"
.align 3
_start:
.quad ._start, .TOC.@tocbase, 0
.previous

.global ._start
._start:
	li 0, 4
	li 3, 1
	lis 4, message@highest
	ori 4, 4, message@higher
	rldicr 4, 4, 32, 31
	oris 4, 4, message@h
	ori 4, 4, message@l
	li 5, len
	sc

	li 0,1
	li 3,1
	sc

