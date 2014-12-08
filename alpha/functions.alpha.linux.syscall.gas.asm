#include <asm/unistd.h>
#include <asm/pal.h>

.arch ev4
.set noreorder
.set nomacro
.set noat
.set volatile

/* read-only data section */
.section .rodata
$message:
	.ascii "hello\n\0"

/* code section, align to 2^2 (4) bytes (size of instruction) */
.section .text
.align 2
.globl _start

_start:	
	bsr  $27,0                        /* setup pv from current pc */
	ldah $29,0($27)!gpdisp!1          /* get high offset to data section */
	lda  $29,0($29)!gpdisp!1          /* get low offset to data section */

	ldah $16,$message($29)!gprelhigh
	lda  $16,$message($16)!gprellow
	bsr  $26,puts

	lda  $16,0($31)
	bsr  $26,exit

exit:
	lda  $0, __NR_exit($31)
	callsys

/* long rol(long x, long count); */
rol:
	lda $1,63($31)
	and $1,$17,$2
	sll $16,$2,$3
	lda $4,64($31)
	subq $4,$2,$5
	sra $16,$5,$6
	bis $6,$3,$0
	ret

/* long ror(long x, long count); */
ror:
	lda $1,63($31)
	and $1,$17,$2
	sra $16,$2,$3
	lda $4,64($31)
	subq $4,$2,$5
	sll $16,$5,$6
	bis $6,$3,$0
	ret


strlen:
	lda $0,0($31)          /* char count */
	lda $1,7($31)          /* quad mask */
strlen$quadloop:
	ldq_u $5,0($16)        /* read quad */
strlen$byteloop:
	and $16,$1,$3          /* byte offset within quad */
	extbl $5,$3,$6         /* get byte */
	beq $6,strlen$done     /* byte 0 => done */
	addq $0,1,$0           /* increment count */
	addq $16,1,$16         /* increment address */
	cmpeq $3,7,$7          /* if last offset */
	beq $7,strlen$quadloop /* read new quad */
	br strlen$byteloop     /* else loop over all bytes in quad */
strlen$done:
	ret


puts:
	lda $sp,-16($sp) /* allocate space for ra copy */
	stq $26,0($sp)   /* save ra */
	stq $16,8($sp)   /* save a0 */
	bsr $26,strlen

	lda $18,0($0)
	lda $0, __NR_write($31)          
	ldq $17,8($sp)   /* load saved a0 */
	lda $16,1($31)
	callsys

	ldq $26,0($sp)  /* restore ra */
	lda $sp,16($sp) /* cleanup stack */
	ret


.section .text

unaligned_read:
    ldq_u  $2, ($16)        # Load lower quadword
    ldq_u  $3, 3($16)       # Load upper quadword
    extll  $2, $16, $2      # Extract lower part
    extlh  $3, $16, $3      # Extract upper part
    bis    $2, $3, $0       # Join lower and upper part
    sextl  $0, $0           # Extend sign bit


load 64-bit immediate
   0:   34 12 1f 24     ldah    v0,4660
   4:   79 56 00 20     lda     v0,22137(v0)
   8:   20 17 04 48     sll     v0,0x20,v0
   c:   bd 9a 00 24     ldah    v0,-25923(v0)
  10:   f0 de 00 20     lda     v0,-8464(v0)
  14:   01 80 fa 6b     ret

-mbuild-constants behaviour ^

; $17 = ($16 == 3) ? 40 : 41;
lda  $1,0($16)
cmpeq $1,3,$1
cmoveq $1,40,$17
cmovne $1,41,$17

