Registers
=========

The functions of the registers are defined by the calling-convention of the
operating system rather than the hardware specification.

The following is the OSF/1 (UNIX) convention :

|Register|Name |Description          |Preserved across procedure calls|
|--------|-----|---------------------|--------------------------------|
|       0|v0   |Function result      |No                              |
|       1|t0   |Temporary            |No                              |
|       2|t1   |"                    |No                              |
|       3|t2   |"                    |No                              |
|       4|t3   |"                    |No                              |
|       5|t4   |"                    |No                              |
|       6|t5   |"                    |No                              |
|       7|t6   |"                    |No                              |
|       8|t7   |"                    |No                              |
|       9|s0   |Saved                |Yes                             |
|      10|s1   |"                    |Yes                             |
|      11|s2   |"                    |Yes                             |
|      12|s3   |"                    |Yes                             |
|      13|s4   |"                    |Yes                             |
|      14|s5   |"                    |Yes                             |
|      15|fp/s6|Frame pointer / saved|? / Yes                         |
|      16|a0   |Function arguments   |No                              |
|      17|a1   |"                    |No                              |
|      18|a2   |"                    |No                              |
|      19|a3   |"                    |No                              |
|      20|a4   |"                    |No                              |
|      21|a5   |"                    |No                              |
|      22|t8   |Temporary            |No                              |
|      23|t9   |"                    |No                              |
|      24|t10  |"                    |No                              |
|      25|t11  |"                    |No                              |
|      26|ra   |Return address       |Yes                             |
|      27|pv/t1|Procedure value      |No                              |
|      28|at   |Assembler temporary  |No                              |
|      29|gp   |Global pointer       |No                              |
|      30|sp   |Stack pointer        |Yes                             |
|      31|zero |Always zero          |n/a                             |

Relocations
===========

* !literal
* !literal!N

Used with an ldq instruction to load the address of a symbol from the GOT.
A sequence number N is optional, and if present is used to pair lituse
relocations with this literal relocation. The lituse relocations are used by
the linker to optimize the code based on the final location of the symbol.

* !lituse_base!N

Used with any memory format instruction (e.g. ldl) to indicate that the literal
is used for an address load. The offset field of the instruction must be zero.
During relaxation, the code may be altered to use a gp-relative load.

* !lituse_jsr!N

Used with a register branch format instruction (e.g. jsr) to indicate that the
literal is used for a call. During relaxation, the code may be altered to use
a direct branch (e.g. bsr).

* !lituse_jsrdirect!N

Similar to lituse_jsr, but also that this call cannot be vectored through a PLT
entry. This is useful for functions with special calling conventions which do
not allow the normal call-clobbered registers to be clobbered.

* !lituse_bytoff!N

Used with a byte mask instruction (e.g. extbl) to indicate that only the low 3
bits of the address are relevant. During relaxation, the code may be altered
to use an immediate instead of a register shift.

* !lituse_addr!N

Used with any other instruction to indicate that the original address is in
fact used, and the original ldq instruction may not be altered or deleted.
This is useful in conjunction with lituse_jsr to test whether a weak symbol
is defined.
```Assembly
	ldq  $27,foo($29)   !literal!1
	beq  $27,is_undef   !lituse_addr!1
	jsr  $26,($27),foo  !lituse_jsr!1
```

* !lituse_tlsgd!N

Used with a register branch format instruction to indicate that the literal
is the call to __tls_get_addr used to compute the address of the thread-local
storage variable whose descriptor was loaded with !tlsgd!N.

* !lituse_tlsldm!N

Used with a register branch format instruction to indicate that the literal
is the call to __tls_get_addr used to compute the address of the base of the
thread-local storage block for the current module. The descriptor for the
module must have been loaded with !tlsldm!N.

* !gpdisp!N

Used with ldah and lda to load the GP from the current address, a-la the ldgp
macro. The source register for the ldah instruction must contain the address
of the ldah instruction. There must be exactly one lda instruction paired with
the ldah instruction, though it may appear anywhere in the instruction stream.
The immediate operands must be zero.
```Assembly
	bsr  $26,foo
	ldah $29,0($26)     !gpdisp!1
	lda  $29,0($29)     !gpdisp!1
```

* !gprelhigh

Used with an ldah instruction to add the high 16 bits of a 32-bit displacement
from the GP.

* !gprellow
Used with any memory format instruction to add the low 16 bits of a 32-bit
displacement from the GP.

* !gprel

Used with any memory format instruction to add a 16-bit displacement from
the GP.

* !samegp

Used with any branch format instruction to skip the GP load at the target
address. The referenced symbol must have the same GP as the source object
file, and it must be declared to either not use $27 or perform a standard GP
load in the first two instructions via the .prologue directive.

* !tlsgd
* !tlsgd!N

Used with an lda instruction to load the address of a TLS descriptor for a
symbol in the GOT.  The sequence number N is optional, and if present it used
to pair the descriptor load with both the literal loading the address of the
`__tls_get_addr` function and the `lituse_tlsgd` marking the call to that function.

* !tlsldm
* !tlsldm!N

Used with an lda instruction to load the address of a TLS descriptor for the
current module in the GOT.  Similar in other respects to tlsgd.

* !gotdtprel

Used with an ldq instruction to load the offset of the TLS symbol within its
module's thread-local storage block. Also known as the dynamic thread pointer
offset or dtp-relative offset.

* !dtprelhi
* !dtprello
* !dtprel

Like gprel relocations except they compute dtp-relative offsets.

* !gottprel

Used with an ldq instruction to load the offset of the TLS symbol from the
thread pointer. Also known as the tp-relative offset.

* !tprelhi
* !tprello
* !tprel

Like gprel relocations except they compute tp-relative offsets.


Virtual Memory
==============

On a TLB miss, a PALcode routine is called which loads the TLB entry with
the new virtual-to-physical mapping as defined by the page table structure
pointed to by the PTBR (page-table base register).

Page table structure is thus defined by PALcode implementation rather than the
hardware specification.

The page table layout for OSF/1 (used in Tru64 UNIX and UNIX-like operating
systems such as Linux), using 8k pages is :

```
666555555555554444444|4443333333|3332222222|2221111111|11
321098765432109876543|2109876543|2109876543|2109876543|2109876543210
---------------------+----------+----------+----------+-------------
uuuuuuuuuuuuuuuuuuuuu|aaaaaaaaaa|bbbbbbbbbb|cccccccccc|ooooooooooooo
```

u : unused
a : PTE index of root page table   (10 bits)
b : PTE index of middle page table (10 bits)
c : PTE index of leaf page table   (10 bits)
o : page offset                    (13 bits)

- which allows for a virtual address space of 1G pages == 8TiB

These sizes are defined in /usr/include/asm/osf.h as follows :

```
#define VA_V_SEG1       33
#define VA_M_SEG1       (0x3FF<<VA_V_SEG1)
#define VA_V_SEG2       23
#define VA_M_SEG2       (0x3FF<<VA_V_SEG2)
#define VA_V_SEG3       13
#define VA_M_SEG3       (0x3FF<<VA_V_SEG3)
#define VA_V_OFFSET     0
#define VA_M_OFFSET     0x1FFF

#define VA_S_SIZE       43
#define VA_S_OFF        13
#define VA_S_SEG        10
#define VA_S_PAGE_SIZE  8192
```

Instruction Aliases
===================

Alpha has a very orthogonal instruction set, which together with its flexible
register usage, results in the same opcode being used for multiple operations
which might have seperate opcodes on other architectures.

| Pseudo Instruction | Actual Instruction  |
| ------------------ | ------------------- |
| nop                | bis   $31,$31,$31   |
| fnop               | cpys  $31,$31,$f31  |
| clr                | bis   $31,$31,$x    |
| fclr               | cpys  $f31,$f31,$fx |
| unop               | ldq_u $31,0($x)     |
| mov    #lit8,$y    | bis   $31,lit8,$y   |
| mov    $x,$y       | bis   $x,$x,$y      |
| negl   $x,$y       | subl  $31,$x,$y     |
| negq   $x,$y       | subq  $31,$x,$y     |
| not    $x,$y       | ornot $31,$x,$y     |
| or     $x,$y,$z    | bis   $x,$y,$z      |
| andnot $x,$y,$z    | bic   $x,$y,$z      |
| fmov   $fx,$fy     | cpys  $fx,$fx,$fy   |
| fnegs  $fx,$fy     | cpysn $fx,$fx,$fy   |
| fnegt  $fx,$fy     | cpytn $fx,$fx,$fy   |


Instruction Formats
==================

General Format
--------------

<table>
	<tr>
		<td>31..26</td>
		<td>25..21</td>
		<td>20..16</td>
		<td>15..13</td>
		<td>12</td>
		<td>11</td>
		<td>10..9</td>
		<td>8..5</td>
		<td>4..0</td>
		<td>Category</td>
	</tr>
	<tr>
		<td>000000</td>
		<td colspan="8">index</td>
		<td>PAL call</td>
	</tr>
	<tr>
		<td>opcode</td>
		<td>Ra</td>
		<td>Rb</td>
		<td>unused</td>
		<td>0</td>
		<td colspan="3">function</td>
		<td>Rc</td>
		<td>ALU operation</td>
	</tr>
	<tr>
		<td>opcode</td>
		<td>Ra</td>
		<td colspan="2">immediate</td>
		<td>1</td>
		<td colspan="3">function</td>
		<td>Rc</td>
		<td>ALU/Memory operation</td>
	</tr>
	<tr>
		<td>opcode</td>
		<td>FRa</td>
		<td>FRb</td>
		<td>type</td>
		<td colspan="2">round</td>
		<td>size</td>
		<td>function</td>
		<td>FRc</td>
		<td>Floating-point operation</td>
	</tr>
	<tr>
		<td>opcode</td>
		<td>Ra</td>
		<td colspan="7">displacement</td>
		<td>PC-relative branch</td>
	</tr>
	<tr>
		<td>opcode</td>
		<td>Ra</td>
		<td>Rb</td>
		<td colspan=6">displacement</td>
		<td>Register-relative branch</td>
	</tr>
</table>

Specific Opcodes
----------------

33222222222211111111110000000000
10987654321098765432109876543210
--------------------------------
000000iiiiiiiiiiiiiiiiiiiiiiiiii call_pal imm
000001?????????????????????????? opc01
000010?????????????????????????? opc02
000011?????????????????????????? opc03
000100?????????????????????????? opc04
000101?????????????????????????? opc05
000110?????????????????????????? opc06
000111?????????????????????????? opc07

001000aaaaabbbbboooooooooooooooo lda   ra,o(rb)
001001aaaaabbbbboooooooooooooooo ldah  ra,o(rb)
001010aaaaabbbbboooooooooooooooo ldbu  ra,o(rb)
001011aaaaabbbbboooooooooooooooo ldq_u ra,o(rb)

001100aaaaabbbbboooooooooooooooo ldwu  ra,o(rb)
001101aaaaabbbbboooooooooooooooo stw   ra,o(rb)
001110aaaaabbbbboooooooooooooooo stb   ra,o(rb)
001110aaaaabbbbboooooooooooooooo stq_u ra,o(rb)

01000000000000001110000000000000 rc v0
01000000000000001111000000000000 rs v0
010000aaaaa111111100000000000000 rpcc ra

010000aaaaabbbbbuuu00000000ccccc addl   ra,rb,rc
010000aaaaabbbbbuuu00000010ccccc s4addl ra,rb,rc
010000aaaaabbbbbuuu00001001ccccc subl   ra,rb,rc
010000aaaaabbbbbuuu00001011ccccc s4subl ra,rb,rc
010000aaaaabbbbbuuu00001111ccccc cmpbge ra,rb,rc
010000aaaaabbbbbuuu00010010ccccc s8addl ra,rb,rc
010000aaaaabbbbbuuu00011011ccccc s8subl ra,rb,rc
010000aaaaabbbbbuuu00011101ccccc cmpult ra,rb,rc

010000aaaaabbbbbuuu00100000ccccc addq   ra,rb,rc
010000aaaaabbbbbuuu00100010ccccc s4addq ra,rb,rc
010000aaaaabbbbbuuu00101001ccccc subq   ra,rb,rc
010000aaaaabbbbbuuu00101011ccccc s4subq ra,rb,rc
010000aaaaabbbbbuuu00101111ccccc cmpeq  ra,rb,rc
010000aaaaabbbbbuuu00110010ccccc s8addq ra,rb,rc
010000aaaaabbbbbuuu00111011ccccc s8subq ra,rb,rc
010000aaaaabbbbbuuu00111101ccccc cmpule ra,rb,rc

010000aaaaabbbbbuuu01000000ccccc addl/v ra,rb,rc
010000aaaaabbbbbuuu01001001ccccc subl/v ra,rb,rc
010000aaaaabbbbbuuu01001101ccccc cmplt  ra,rb,rc
010000aaaaabbbbbuuu01100000ccccc addq/v ra,rb,rc
010000aaaaabbbbbuuu01101001ccccc subq/v ra,rb,rc
010000aaaaabbbbbuuu01101101ccccc cmple  ra,rb,rc

01000011111bbbbbuuu00000000ccccc sextl rb,rc
01000011111bbbbbuuu00101001ccccc negq  rb,rc

010001aaaaabbbbbuuu00000000ccccc and     ra,rb,rc
010001aaaaabbbbbuuu00001000ccccc bic     ra,rb,rc
010001aaaaabbbbbuuu00010100ccccc cmovlbs ra,rb,rc
010001aaaaabbbbbuuu00010110ccccc cmovlbc ra,rb,rc
010001aaaaabbbbbuuu00100000ccccc bis     ra,rb,rc
010001aaaaabbbbbuuu00100100ccccc cmoveq  ra,rb,rc
010001aaaaabbbbbuuu00100110ccccc cmovne  ra,rb,rc
010001aaaaabbbbbuuu00101000ccccc ornor   ra,rb,rc
010001aaaaabbbbbuuu01000000ccccc xor     ra,rb,rc
010001aaaaabbbbbuuu01000100ccccc cmovlt  ra,rb,rc
010001aaaaabbbbbuuu01000110ccccc cmovge  ra,rb,rc
010001aaaaabbbbbuuu01001000ccccc eqv     ra,rb,rc
010001aaaaabbbbbuuu01100001ccccc amask   ra,rb,rc
010001aaaaabbbbbuuu01100100ccccc cmovle  ra,rb,rc
010001aaaaabbbbbuuu01100110ccccc cmovgt  ra,rb,rc
010001111110000000111101100ccccc implver rc?

010010aaaaabbbbbuuu00000010ccccc mskbl  ra,rb,rc (int,lit)
010010aaaaabbbbbuuu00000110ccccc extbl  ra,rb,rc (int,lit)
010010aaaaabbbbbuuu00001011ccccc insbl  ra,rb,rc (int,lit)
010010aaaaabbbbbuuu00010010ccccc mskwl  ra,rb,rc (int,lit)
010010aaaaabbbbbuuu00010110ccccc extwl  ra,rb,rc (int,lit)
010010aaaaabbbbbuuu00011011ccccc inswl  ra,rb,rc (int,lit)
010010aaaaabbbbbuuu00100010ccccc mskll  ra,rb,rc (int,lit)
010010aaaaabbbbbuuu00100110ccccc extll  ra,rb,rc (int,lit)
010010aaaaabbbbbuuu00101011ccccc insll  ra,rb,rc (int,lit)
010010aaaaabbbbbuuu00110000ccccc zap    ra,rb,rc (int,lit)
010010aaaaabbbbbuuu00110001ccccc zapnot ra,rb,rc (int,lit)
010010aaaaabbbbbuuu00110010ccccc mskql  ra,rb,rc (int,lit)
010010aaaaabbbbbuuu00110100ccccc srl    ra,rb,rc (int,lit)
010010aaaaabbbbbuuu00110110ccccc extql  ra,rb,rc (int,lit)
010010aaaaabbbbbuuu00111001ccccc sll    ra,rb,rc (int,lit)
010010aaaaabbbbbuuu00111011ccccc insql  ra,rb,rc (int,lit)
010010aaaaabbbbbuuu00111100ccccc sra    ra,rb,rc (int,lit)
010010aaaaabbbbbuuu01010010ccccc mskwh  ra,rb,rc (int,lit)
010010aaaaabbbbbuuu01010111ccccc inswh  ra,rb,rc (int,lit)
010010aaaaabbbbbuuu01011010ccccc extwh  ra,rb,rc (int,lit)
010010aaaaabbbbbuuu01100010ccccc msklh  ra,rb,rc (int,lit)
010010aaaaabbbbbuuu01100111ccccc inslh  ra,rb,rc (int,lit)
010010aaaaabbbbbuuu01101010ccccc extlh  ra,rb,rc (int,lit)
010010aaaaabbbbbuuu01110010ccccc mskqh  ra,rb,rc (int,lit)
010010aaaaabbbbbuuu01110111ccccc insqh  ra,rb,rc (int,lit)
010010aaaaabbbbbuuu01111010ccccc extqh  ra,rb,rc (int,lit)

010011aaaaabbbbbuuu00000000ccccc mull   ra,rb,rc (int,lit)
010011aaaaabbbbbuuu00100000ccccc mulq   ra,rb,rc (int,lit)
010011aaaaabbbbbuuu00110000ccccc umulh  ra,rb,rc (int,lit)
010011aaaaabbbbbuuu01000000ccccc mull/v ra,rb,rc (int,lit)
010011aaaaabbbbbuuu01100000ccccc mulq/v ra,rb,rc (int,lit)

010100aaaaabbbbbuuu00000100ccccc itofs (regs?)
010100aaaaabbbbbuuu00001010ccccc sqrtf/c (regs?)
010100aaaaabbbbbuuu00001011ccccc sqrts/c (regs?)
010100aaaaabbbbbuuu00101010ccccc sqrtg/c (regs?)
010100aaaaabbbbbuuu00101011ccccc sqrtt/c (regs?)
010100aaaaabbbbbuuu01001011ccccc sqrts/m (regs?)
010100aaaaabbbbbuuu01101011ccccc sqrtt/m (regs?)
010100aaaaabbbbbuuu10001010ccccc sqrtf   (regs?)
010100aaaaabbbbbuuu10001011ccccc sqrts   (regs?)
010100aaaaabbbbbuuu10101010ccccc sqrtg   (regs?)
010100aaaaabbbbbuuu10101011ccccc sqrtt   (regs?)
010100aaaaabbbbbuuu10101010ccccc sqrtg   (regs?)
010100aaaaabbbbbuuu10101011ccccc sqrtt   (regs?)


010100aaaaabbbbbuuu00001011ccccc sqrts (regs?)
010100aaaaabbbbbuuu00010100ccccc itoff (regs?)
010100aaaaabbbbbuuu00100100ccccc itoft (regs?)
010100aaaaabbbbbuuu00101010ccccc sqrtg (regs?)
010100aaaaabbbbbuuu00101011ccccc sqrtt (regs?)

VAX floating point
------------------

ttt trapping mode
--- -------------
000 Imprecise (default)
001 Underflow enable (/u) floating-point output
    Overflow enable (/v)  integer output
010 Unsupported
011 Unsupported
100 Unsupported
101 /su floating-point output
    /sv integer output
110 Unsupported
111 /sui floating-point output
    /svi integer output

rr rounding mode
-- -------------
00 chopped (/c)
01 minus infinity (/m)
10 normal (default)
11 dynamic (/d)

ss source datatype
-- ---------------
00 S_float
01 Reserved
10 T_float
11 Q_fixed

010101aaaaabbbbbtttrrss0000ccccc add(s)/q1 fa,fb,fc
010101aaaaabbbbbtttrrss0001ccccc sub(s)/q1 fa,fb,fc
010101aaaaabbbbbtttrrss0010ccccc mul(s)/q1 fa,fb,fc
010101aaaaabbbbbtttrrss0011ccccc div(s)/q1 fa,fb,fc
010101aaaaabbbbbtttrrss0100ccccc cmpxun(s)/q1 fa,fb,fc
010101aaaaabbbbbtttrrss0101ccccc cmpxeq(s)/q1 fa,fb,fc
010101aaaaabbbbbtttrrss0110ccccc cmpxlt(s)/q1 fa,fb,fc
010101aaaaabbbbbtttrrss0111ccccc cmpxle(s)/q1 fa,fb,fc
010101_________________1000_____ reserved
010101_________________1001_____ reserved
010101_________________1010_____ reserved
010101_________________1011_____ reserved
01010111111bbbbbtttrrss1100ccccc cvt(s)s/q1 fb,fc
010101_________________1101_____ reserved
01010111111bbbbbtttrrss1110ccccc cvt(s)t/q1 fb,fc
01010111111bbbbbtttrrss1111ccccc cvt(s)q/q1 fb,fc

IEEE floating point
-------------------

ttt trapping mode
--- -------------
000 Imprecise (default)
001 Underflow enable (/u) floating-point output
    Overflow enable (/v)  integer output
010 Unsupported
011 Unsupported
100 Software completion enable (/s)
101 /su floating-point output
    /sv integer output
110 Unsupported
111 Unsupported

rr rounding mode
-- -------------
00 chopped (/c)
01 Unsupported
10 normal (default)
11 Unsupported

ss source datatype
-- ---------------
00 F_float
01 D_float
10 G_float
11 Q_fixed

010110aaaaabbbbbtttrrss0000ccccc add(s)/q1 fa,fb,fc
010110aaaaabbbbbtttrrss0001ccccc sub(s)/q1 fa,fb,fc
010110aaaaabbbbbtttrrss0010ccccc mul(s)/q1 fa,fb,fc
010110aaaaabbbbbtttrrss0011ccccc div(s)/q1 fa,fb,fc
010110aaaaabbbbbtttrrss0100ccccc cmpxun(s)/q1 fa,fb,fc
010110aaaaabbbbbtttrrss0101ccccc cmpxeq(s)/q1 fa,fb,fc
010110aaaaabbbbbtttrrss0110ccccc cmpxlt(s)/q1 fa,fb,fc
010110aaaaabbbbbtttrrss0111ccccc cmpxle(s)/q1 fa,fb,fc
010110_________________1000_____ reserved
010110_________________1001_____ reserved
010110_________________1010_____ reserved
010110_________________1011_____ reserved
01011011111bbbbbtttrrss1100ccccc cvt(s)f/q1 fb,fc
01011011111bbbbbtttrrss1101ccccc cvt(s)d/q1 fb,fc
01011011111bbbbbtttrrss1110ccccc cvt(s)g/q1 fb,fc
01011011111bbbbbtttrrss1111ccccc cvt(s)q/q1 fb,fc

01010111111 aaaaa q____ ss0001 fb___ neg(s=f/g)/q3 fa,fb

01011011111 aaaaa q____ 101111 fb___ cvttq/q7 fa,fb
01011011111 aaaaa q____ 111100 fb___ cvtqs/q9 fa,fb
01011011111 aaaaa q____ 111110 fb___ cvtqt/q9 fa,fb
01010111111 aaaaa q____ 101111 fb___ cvtgq/q6 $fa,$fb
01011011111 aaaaa q____ 101100 fb___ cvtts/q2 fa,fb
01011011111 aaaaa q____ 101100 fb___ cvtst/q3 fa,fb

01011111111 fa___ 00000 001000 fb___ cvtlq    fa,fb

01011111111 11111 00000 100000 fa___ fclr fa
01011111111 fa___ 00000 100000 fb___ fabs fa,fb
010111aaaaa fb___ 00001 000000 fb___ fneg fa,fb

01011111111 fa___ q____ 110000 fb___ cvtql/q5 fa,fb


01100000000000000000000000000000 trapb
01100000000000000000010000000000 excb
01100000000000000100000000000000 mb
01100000000000000100010000000000 wmb
011001iiiiiiiiiiiiiiiiiiiiiiiiii pal19 i
011001aaaaaooooooooooooooooooooo mfpr ra, o ; EV67+?

011010aaaaabbbbboooooooooooooooo jmp ra,(rb),o

0110110000000000iiiiiiiiiiiiiiii pal1b i
0111000000000000iiiiiiiiiiiiiiii pal1c i
01110011111100000000011000000000 ctpop a0,v0 ; EV67+
0111010000000000iiiiiiiiiiiiiiii pal1d i
01110111111111010000000000110010 mtpr gp, ptPgp

0111100000000000iiiiiiiiiiiiiiii pal1e i
0111110000000000iiiiiiiiiiiiiiii pal1f i

100000aaaaabbbbboooooooooooooooo ldf fa,o(rb)
100001aaaaabbbbboooooooooooooooo ldg fa,o(rb)
100010aaaaabbbbboooooooooooooooo lds fa,o(rb)
100011aaaaabbbbboooooooooooooooo ldt fa,o(rb)

100100aaaaabbbbboooooooooooooooo stf fa,o(rb)
100101aaaaabbbbboooooooooooooooo stg fa,o(rb)
100110aaaaabbbbboooooooooooooooo sts fa,o(rb)
100111aaaaabbbbboooooooooooooooo stt fa,o(rb)

101000aaaaabbbbboooooooooooooooo ldl   Ra,o(Rb)
101001aaaaabbbbboooooooooooooooo ldq   Ra,o(Rb)
101010aaaaabbbbboooooooooooooooo ldl_l Ra,o(Rb)
101011aaaaabbbbboooooooooooooooo ldq_l Ra,o(Rb)

101100aaaaabbbbboooooooooooooooo stl   Ra,o(Rb)
101101aaaaabbbbboooooooooooooooo stq   Ra,o(Rb)
101110aaaaabbbbboooooooooooooooo stl_c Ra,o(Rb)
101111aaaaabbbbboooooooooooooooo stq_c Ra,o(Rb)

110000aaaaaooooooooooooooooooooo br   Ra,disp
110001aaaaaooooooooooooooooooooo fbeq Ra,disp
110010aaaaaooooooooooooooooooooo fblt Ra,disp
110011aaaaaooooooooooooooooooooo fble Ra,disp
110100aaaaaooooooooooooooooooooo bsr  Ra,disp
110101aaaaaooooooooooooooooooooo fbne Ra,disp
110110aaaaaooooooooooooooooooooo fbge Ra,disp
110111aaaaaooooooooooooooooooooo fbgt Ra,disp
111000aaaaaooooooooooooooooooooo blbc Ra,disp
111001aaaaaooooooooooooooooooooo beq  Ra,disp
111010aaaaaooooooooooooooooooooo blt  Ra,disp
111011aaaaaooooooooooooooooooooo ble  Ra,disp
111100aaaaaooooooooooooooooooooo blbs Ra,disp
111101aaaaaooooooooooooooooooooo bne  Ra,disp
111110aaaaaooooooooooooooooooooo bge  Ra,disp
111111aaaaaooooooooooooooooooooo bgt  Ra,disp
