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
| sextl  $x,$y       | addl  $31,$x,$y     |
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
		<td>Fa</td>
		<td>Fb</td>
		<td>type</td>
		<td colspan="2">round</td>
		<td>size</td>
		<td>function</td>
		<td>Fc</td>
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
		<td colspan="6">displacement</td>
		<td>Register-relative branch</td>
	</tr>
</table>

Instructions
----------------

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
		<td>call_pal index</td>
	</tr>
	<tr>
		<td>000001</td>
		<td colspan="8">?</td>
		<td>opc01</td>
	</tr>
	<tr>
		<td>000010</td>
		<td colspan="8">?</td>
		<td>opc02</td>
	</tr>
	<tr>
		<td>000011</td>
		<td colspan="8">?</td>
		<td>opc03</td>
	</tr>
	<tr>
		<td>000100</td>
		<td colspan="8">?</td>
		<td>opc04</td>
	</tr>
	<tr>
		<td>000101</td>
		<td colspan="8">?</td>
		<td>opc05</td>
	</tr>
	<tr>
		<td>000110</td>
		<td colspan="8">?</td>
		<td>opc06</td>
	</tr>
	<tr>
		<td>000111</td>
		<td colspan="8">?</td>
		<td>opc07</td>
	</tr>	
	<tr>
		<td>001000</td>
		<td>ra</td>
		<td>rb</td>
		<td colspan="6">disp</td>
		<td>lda ra,disp(rb)</td>
	</tr>
	<tr>
		<td>001001</td>
		<td>ra</td>
		<td>rb</td>
		<td colspan="6">disp</td>
		<td>ldah ra,disp(rb)</td>
	</tr>
	<tr>
		<td>001010</td>
		<td>ra</td>
		<td>rb</td>
		<td colspan="6">disp</td>
		<td>ldbu ra,disp(rb)</td>
	</tr>
	<tr>
		<td>001011</td>
		<td>ra</td>
		<td>rb</td>
		<td colspan="6">disp</td>
		<td>ldq_u ra,disp(rb)</td>
	</tr>
	<tr>
		<td>001100</td>
		<td>ra</td>
		<td>rb</td>
		<td colspan="6">disp</td>
		<td>ldwu ra,disp(rb)</td>
	</tr>
	<tr>
		<td>001101</td>
		<td>ra</td>
		<td>rb</td>
		<td colspan="6">disp</td>
		<td>stw ra,disp(rb)</td>
	</tr>
	<tr>
		<td>001110</td>
		<td>ra</td>
		<td>rb</td>
		<td colspan="6">disp</td>
		<td>stb ra,disp(rb)</td>
	</tr>
	<tr>
		<td>001111</td>
		<td>ra</td>
		<td>rb</td>
		<td colspan="6">disp</td>
		<td>stq_u ra,disp(rb)</td>
	</tr>
	<tr>
		<td>010000</td>
		<td>ra</td>
		<td>00000</td>
		<td>111</td>
		<td colspan="5">0000000000000</td>
		<td>rc ra</td>
	</tr>	
	<tr>
		<td>010000</td>
		<td>ra</td>
		<td>00000</td>
		<td>111</td>
		<td colspan="5">1000000000000</td>
		<td>rs ra</td>
	</tr>			
	<tr>
		<td>010000</td>
		<td>ra</td>
		<td>11111</td>
		<td>110</td>
		<td colspan="5">0000000000000</td>
		<td>rpcc ra</td>
	</tr>
	<tr>
		<td colspan="10">Arithmetic group</td>
	</tr>	
	<tr>
		<td>010000</td>
		<td>Ra</td>
		<td>Rb</td>
		<td>unused</td>
		<td>0</td>
		<td colspan="3">0000000</td>
		<td>Rc</td>
		<td>addl ra,rb,rc</td>
	</tr>
	<tr>
		<td>010000</td>
		<td>Ra</td>
		<td>Rb</td>
		<td>unused</td>
		<td>0</td>
		<td colspan="3">0000010</td>
		<td>Rc</td>
		<td>s4addl ra,rb,rc</td>
	</tr>
	<tr>
		<td>010000</td>
		<td>Ra</td>
		<td>Rb</td>
		<td>unused</td>
		<td>0</td>
		<td colspan="3">0001001</td>
		<td>Rc</td>
		<td>subl ra,rb,rc</td>
	</tr>
	<tr>
		<td>010000</td>
		<td>Ra</td>
		<td>Rb</td>
		<td>unused</td>
		<td>0</td>
		<td colspan="3">0001011</td>
		<td>Rc</td>
		<td>s4subl ra,rb,rc</td>
	</tr>
	<tr>
		<td>010000</td>
		<td>Ra</td>
		<td>Rb</td>
		<td>unused</td>
		<td>0</td>
		<td colspan="3">0001111</td>
		<td>Rc</td>
		<td>cmpbge ra,rb,rc</td>
	</tr>
	<tr>
		<td>010000</td>
		<td>Ra</td>
		<td>Rb</td>
		<td>unused</td>
		<td>0</td>
		<td colspan="3">0010010</td>
		<td>Rc</td>
		<td>s8addl ra,rb,rc</td>
	</tr>
	<tr>
		<td>010000</td>
		<td>Ra</td>
		<td>Rb</td>
		<td>unused</td>
		<td>0</td>
		<td colspan="3">0011010</td>
		<td>Rc</td>
		<td>s8subl ra,rb,rc</td>
	</tr>
	<tr>
		<td>010000</td>
		<td>Ra</td>
		<td>Rb</td>
		<td>unused</td>
		<td>0</td>
		<td colspan="3">0011101</td>
		<td>Rc</td>
		<td>cmpult ra,rb,rc</td>
	</tr>

	<tr>
		<td>010000</td>
		<td>Ra</td>
		<td>Rb</td>
		<td>unused</td>
		<td>0</td>
		<td colspan="3">0100000</td>
		<td>Rc</td>
		<td>addq ra,rb,rc</td>
	</tr>
	<tr>
		<td>010000</td>
		<td>Ra</td>
		<td>Rb</td>
		<td>unused</td>
		<td>0</td>
		<td colspan="3">0100010</td>
		<td>Rc</td>
		<td>s4addq ra,rb,rc</td>
	</tr>
	<tr>
		<td>010000</td>
		<td>Ra</td>
		<td>Rb</td>
		<td>unused</td>
		<td>0</td>
		<td colspan="3">0101001</td>
		<td>Rc</td>
		<td>subq ra,rb,rc</td>
	</tr>
	<tr>
		<td>010000</td>
		<td>Ra</td>
		<td>Rb</td>
		<td>unused</td>
		<td>0</td>
		<td colspan="3">0101011</td>
		<td>Rc</td>
		<td>s4subq ra,rb,rc</td>
	</tr>
	<tr>
		<td>010000</td>
		<td>Ra</td>
		<td>Rb</td>
		<td>unused</td>
		<td>0</td>
		<td colspan="3">0101111</td>
		<td>Rc</td>
		<td>cmpeq ra,rb,rc</td>
	</tr>
	<tr>
		<td>010000</td>
		<td>Ra</td>
		<td>Rb</td>
		<td>unused</td>
		<td>0</td>
		<td colspan="3">0110010</td>
		<td>Rc</td>
		<td>s8addq ra,rb,rc</td>
	</tr>
	<tr>
		<td>010000</td>
		<td>Ra</td>
		<td>Rb</td>
		<td>unused</td>
		<td>0</td>
		<td colspan="3">0111010</td>
		<td>Rc</td>
		<td>s8subq ra,rb,rc</td>
	</tr>
	<tr>
		<td>010000</td>
		<td>Ra</td>
		<td>Rb</td>
		<td>unused</td>
		<td>0</td>
		<td colspan="3">0111101</td>
		<td>Rc</td>
		<td>cmpule ra,rb,rc</td>
	</tr>

	<tr>
		<td>010000</td>
		<td>Ra</td>
		<td>Rb</td>
		<td>unused</td>
		<td>0</td>
		<td colspan="3">1000000</td>
		<td>Rc</td>
		<td>addl/v ra,rb,rc</td>
	</tr>
	<tr>
		<td>010000</td>
		<td>Ra</td>
		<td>Rb</td>
		<td>unused</td>
		<td>0</td>
		<td colspan="3">1001001</td>
		<td>Rc</td>
		<td>subl/v ra,rb,rc</td>
	</tr>
	<tr>
		<td>010000</td>
		<td>Ra</td>
		<td>Rb</td>
		<td>unused</td>
		<td>0</td>
		<td colspan="3">1001101</td>
		<td>Rc</td>
		<td>cmplt ra,rb,rc</td>
	</tr>
	<tr>
		<td>010000</td>
		<td>Ra</td>
		<td>Rb</td>
		<td>unused</td>
		<td>0</td>
		<td colspan="3">1100000</td>
		<td>Rc</td>
		<td>addq/v ra,rb,rc</td>
	</tr>
	<tr>
		<td>010000</td>
		<td>Ra</td>
		<td>Rb</td>
		<td>unused</td>
		<td>0</td>
		<td colspan="3">1101001</td>
		<td>Rc</td>
		<td>subq/v ra,rb,rc</td>
	</tr>	
	<tr>
		<td>010000</td>
		<td>Ra</td>
		<td>Rb</td>
		<td>unused</td>
		<td>0</td>
		<td colspan="3">1101101</td>
		<td>Rc</td>
		<td>cmple ra,rb,rc</td>
	</tr>
	<tr>
		<td colspan="10">Bitwise logic</td>
	</tr>
	<tr>
		<td rowspan="16">010001</td>
		<td rowspan="15">Ra</td>
		<td rowspan="15">Rb</td>
		<td rowspan="15">unused</td>
		<td rowspan="15">0</td>
		<td colspan="3">0000000</td>
		<td rowspan="16">Rc</td>
		<td>and ra,rb,rc</td>
	</tr>
	<tr>
		<td colspan="3">0001000</td>
		<td>bic ra,rb,rc</td>
	</tr>
	<tr>
		<td colspan="3">0010100</td>
		<td>cmovlbs ra,rb,rc</td>
	</tr>
	<tr>
		<td colspan="3">0010110</td>
		<td>cmovlbc ra,rb,rc</td>
	</tr>
	<tr>
		<td colspan="3">0100000</td>
		<td>bis ra,rb,rc</td>
	</tr>
	<tr>
		<td colspan="3">0100100</td>
		<td>cmoveq ra,rb,rc</td>
	</tr>
	<tr>
		<td colspan="3">0100110</td>
		<td>cmovne ra,rb,rc</td>
	</tr>
	<tr>
		<td colspan="3">0101000</td>
		<td>ornor ra,rb,rc</td>
	</tr>
	<tr>
		<td colspan="3">1000000</td>
		<td>xor ra,rb,rc</td>
	</tr>
	<tr>
		<td colspan="3">1000100</td>
		<td>cmovlt ra,rb,rc</td>
	</tr>	
	<tr>
		<td colspan="3">1000110</td>
		<td>cmovge ra,rb,rc</td>
	</tr>
	<tr>
		<td colspan="3">1001000</td>
		<td>eqv ra,rb,rc</td>
	</tr>
	<tr>
		<td colspan="3">1100001</td>
		<td>amask ra,rb,rc</td>
	</tr>
	<tr>
		<td colspan="3">1100100</td>
		<td>cmovle ra,rb,rc</td>
	</tr>
	<tr>
		<td colspan="3">1100110</td>
		<td>cmovgt ra,rb,rc</td>
	</tr>
	<tr>
		<td>11111</td>
		<td>00000</td>
		<td>001</td>
		<td>1</td>
		<td colspan="3">1101100</td>
		<td>implver Rc</td>
	</tr>	
	<tr>
		<td colspan="10">Mask/insert/extract group</td>
	</tr>
	<tr>
		<td rowspan="26">010010</td>
		<td rowspan="26">Ra</td>
		<td rowspan="26">Rb</td>
		<td rowspan="26">unused</td>
		<td rowspan="26">0</td>
		<td colspan="3">0000010</td>
		<td rowspan="26">Rc</td>
		<td>mskbl ra,rb,rc</td>
	</tr>
	<tr>
		<td colspan="3">0000110</td>
		<td>extbl ra,rb,rc</td>
	</tr>
	<tr>
		<td colspan="3">0001011</td>
		<td>insbl ra,rb,rc</td>
	</tr>
	<tr>
		<td colspan="3">0010010</td>
		<td>mskwl ra,rb,rc</td>
	</tr>
	<tr>
		<td colspan="3">0010110</td>
		<td>extwl ra,rb,rc</td>
	</tr>
	<tr>
		<td colspan="3">0011011</td>
		<td>inswl ra,rb,rc</td>
	</tr>
	<tr>
		<td colspan="3">0100010</td>
		<td>mskll ra,rb,rc</td>
	</tr>
	<tr>
		<td colspan="3">0100110</td>
		<td>extll ra,rb,rc</td>
	</tr>
	<tr>
		<td colspan="3">0101011</td>
		<td>insll ra,rb,rc</td>
	</tr>	
	<tr>
		<td colspan="3">0110000</td>
		<td>zap ra,rb,rc</td>
	</tr>	
	<tr>
		<td colspan="3">0110001</td>
		<td>zapnot ra,rb,rc</td>
	</tr>	
	<tr>
		<td colspan="3">0110010</td>
		<td>mskql ra,rb,rc</td>
	</tr>	
	<tr>
		<td colspan="3">0110100</td>
		<td>srl ra,rb,rc</td>
	</tr>
	<tr>
		<td colspan="3">0110110</td>
		<td>extql ra,rb,rc</td>
	</tr>	
	<tr>
		<td colspan="3">0111001</td>
		<td>sll ra,rb,rc</td>
	</tr>
	<tr>
		<td colspan="3">0111011</td>
		<td>insql ra,rb,rc</td>
	</tr>
	<tr>
		<td colspan="3">0111100</td>
		<td>sra ra,rb,rc</td>
	</tr>	
	<tr>
		<td colspan="3">1010010</td>
		<td>mskwh ra,rb,rc</td>
	</tr>
	<tr>
		<td colspan="3">1010111</td>
		<td>inswh ra,rb,rc</td>
	</tr>	
	<tr>
		<td colspan="3">1011010</td>
		<td>extwh ra,rb,rc</td>
	</tr>
	<tr>
		<td colspan="3">1100010</td>
		<td>msklh ra,rb,rc</td>
	</tr>
	<tr>
		<td colspan="3">1100111</td>
		<td>inslh ra,rb,rc</td>
	</tr>	
	<tr>
		<td colspan="3">1101010</td>
		<td>extlh ra,rb,rc</td>
	</tr>
	<tr>
		<td colspan="3">1110010</td>
		<td>mskqh ra,rb,rc</td>
	</tr>
	<tr>
		<td colspan="3">1110111</td>
		<td>insqh ra,rb,rc</td>
	</tr>	
	<tr>
		<td colspan="3">1111010</td>
		<td>extqh ra,rb,rc</td>
	</tr>

	<tr>
		<td colspan="10">Multiply group</td>
	</tr>

	<tr>
		<td rowspan="5">010011</td>
		<td rowspan="5">Ra</td>
		<td rowspan="5">Rb</td>
		<td rowspan="5">unused</td>
		<td rowspan="5">0</td>
		<td colspan="3">0000000</td>
		<td rowspan="5">Rc</td>
		<td>mull ra,rb,rc</td>
	</tr>
	<tr>
		<td colspan="3">0100000</td>
		<td>mulq ra,rb,rc</td>
	</tr>	
	<tr>
		<td colspan="3">0110000</td>
		<td>umulh ra,rb,rc</td>
	</tr>	
	<tr>
		<td colspan="3">1000000</td>
		<td>mull/v ra,rb,rc</td>
	</tr>
	<tr>
		<td colspan="3">1100000</td>
		<td>mulq/v ra,rb,rc</td>
	</tr>

	<tr>
		<td colspan="10">
			IEEE floating point group

			<table>
				<tr>
					<td>trap</td>
					<td>Trapping mode</td>
				</tr>
				<tr>
					<td>000</td>
					<td>Imprecise (default)</td>
				</tr>
				<tr>
					<td rowspan="2">001</td>
					<td>Underflow enable (/u) (floating-point output)</td>
				</tr>
				<tr>
					<td>Overflow enable (/v)  (integer output)</td>
				</tr>
				<tr>
					<td>010</td>
					<td rowspan="2">Unsupported</td>		
				</tr>
				<tr>
					<td>011</td>
				</tr>
				<tr>
					<td>100</td>
					<td>Software completion enable (/s)</td>
				</tr>
				<tr>
					<td rowspan="2">101</td>
					<td>/su (floating-point output)</td>
				</tr>
				<tr>
					<td>/sv (integer output)</td>
				</tr>
				<tr>
					<td>110</td>
					<td rowspan="2">Unsupported</td>
				</tr>
				<tr>
					<td rowspan="2">111</td>
				</tr>
			</table>

			<table>
				<tr>
					<td>round</td>
					<td>Rounding mode</td>
				</tr>
				<tr>
					<td>00</td>
					<td>Chopped (/c)</td>
				</tr>
				<tr>
					<td>01</td>
					<td>Unsupported</td>
				</tr>
				<tr>
					<td>10</td>
					<td>Normal (default)</td>
				</tr>
				<tr>
					<td>11</td>
					<td>Unsupported</td>
				</tr>
			</table>
				
			<table>
				<tr>
					<td>size</td>
					<td>Data size</td>
				</tr>
				<tr>
					<td>00</td>
					<td>F_float (f)</td>
				</tr>
				<tr>
					<td>01</td>
					<td>D_float (d)</td>
				</tr>
				<tr>
					<td>10</td>
					<td>G_float (g)</td>
				</tr>
				<tr>
					<td>11</td>
					<td>Q_fixed (q)</td>
				</tr>
			</table>		
		</td>
	</tr>

	<tr>
		<td>010100</td>
		<td>111111</td>
		<td>Fb</td>
		<td>trap</td>
		<td colspan="2">round</td>
		<td>size</td>
		<td>1010</td>
		<td>Fc</td>
		<td>sqrt(size)(/round+trap) Fb,Fc</td>
	</tr>
	<tr>
		<td rowspan="16">010110</td>
		<td rowspan="8">Fa</td>
		<td rowspan="8">Fb</td>
		<td rowspan="8">trap</td>
		<td rowspan="8" colspan="2">round</td>
		<td rowspan="8">size</td>
		<td>0000</td>
		<td rowspan="8">Fc</td>
		<td>add(size)(/round+trap) Fa,Fb,Fc</td>
	</tr>
	<tr>
		<td>0001</td>
		<td>sub(size)(/round+trap) Fa,Fb,Fc</td>
	</tr>
	<tr>
		<td>0010</td>
		<td>mul(size)(/round+trap) Fa,Fb,Fc</td>
	</tr>
	<tr>
		<td>0011</td>
		<td>div(size)(/round+trap) Fa,Fb,Fc</td>
	</tr>
	<tr>
		<td>0100</td>
		<td>cmpxun(size)/(q1) Fa,Fb,Fc</td>
	</tr>
	<tr>
		<td>0101</td>
		<td>cmpxeq(size)/(q1) Fa,Fb,Fc</td>
	</tr>
	<tr>
		<td>0110</td>
		<td>cmpxlt(size)/(q1) Fa,Fb,Fc</td>
	</tr>
	<tr>
		<td>0111</td>
		<td>cmpxle(size)/(q1) Fa,Fb,Fc</td>
	</tr>
	<tr>
		<td colspan="6" rowspan="4">-</td>
		<td>1000</td>
		<td rowspan="4">-</td>
		<td rowspan="4">reserved</td>
	</tr>
	<tr>
		<td>1001</td>
	</tr>
	<tr>
		<td>1010</td>
	</tr>
	<tr>
		<td>1011</td>
	</tr>	
	<tr>
		<td rowspan="4">11111</td>
		<td rowspan="4">Fb</td>
		<td rowspan="4">trap</td>
		<td rowspan="4" colspan="2">round</td>
		<td rowspan="4">size</td>
		<td>1100</td>
		<td rowspan="4">Fc</td>
		<td>cvt(size)f/(q1) Fa,Fb,Fc</td>
	</tr>	
	<tr>
		<td>1101</td>
		<td>cvt(size)d/(q1) Fa,Fb,Fc</td>
	</tr>	
	<tr>
		<td>1110</td>
		<td>cvt(size)g/(q1) Fa,Fb,Fc</td>
	</tr>	
	<tr>
		<td>1111</td>
		<td>cvt(size)q/(q1) Fa,Fb,Fc</td>
	</tr>

	<tr>
		<td colspan="10">
			VAX floating point group

			<table>
				<tr>
					<td>trap</td>
					<td>Trapping mode</td>
				</tr>
				<tr>
					<td>000</td>
					<td>Imprecise (default)</td>
				</tr>
				<tr>
					<td rowspan="2">001</td>
					<td>Underflow enable (/u) (floating-point output)</td>
				</tr>
				<tr>
					<td>Overflow enable (/v)  (integer output)</td>
				</tr>
				<tr>
					<td>010</td>
					<td rowspan="3">Unsupported</td>		
				</tr>
				<tr>
					<td>011</td>
				</tr>
				<tr>
					<td>100</td>
				</tr>
				<tr>
					<td rowspan="2">101</td>
					<td>/su (floating-point output)</td>
				</tr>
				<tr>
					<td>/sv (integer output)</td>
				</tr>
				<tr>
					<td>110</td>
					<td>Unsupported</td>
				</tr>
				<tr>
					<td rowspan="2">111</td>
					<td>/sui (floating-point output)</td>
				</tr>
				<tr>
					<td>/svi (integer output)</td>
				</tr>
			</table>

			<table>
				<tr>
					<td>round</td>
					<td>Rounding mode</td>
				</tr>
				<tr>
					<td>00</td>
					<td>Chopped (/c)</td>
				</tr>
				<tr>
					<td>01</td>
					<td>Minus infinity (/m)</td>
				</tr>
				<tr>
					<td>10</td>
					<td>Normal (default)</td>
				</tr>
				<tr>
					<td>11</td>
					<td>Dynamic (/d)</td>
				</tr>
			</table>
				
			<table>
				<tr>
					<td>size</td>
					<td>Data size</td>
				</tr>
				<tr>
					<td>00</td>
					<td>S_float (s)</td>
				</tr>
				<tr>
					<td>01</td>
					<td>Reserved</td>
				</tr>
				<tr>
					<td>10</td>
					<td>T_float (t)</td>
				</tr>
				<tr>
					<td>11</td>
					<td>Q_fixed</td>
				</tr>
			</table>		
		</td>
	</tr>

	<tr>
		<td>010100</td>
		<td>111111</td>
		<td>Fb</td>
		<td>trap</td>
		<td colspan="2">round</td>
		<td>size</td>
		<td>1011</td>
		<td>Fc</td>
		<td>sqrt(size)(/round+trap) Fb,Fc</td>
	</tr>




VAX
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




	<tr>
		<td rowspan="16">010101</td>
		<td rowspan="8">Fa</td>
		<td rowspan="8">Fb</td>
		<td rowspan="8">trap</td>
		<td rowspan="8" colspan="2">round</td>
		<td rowspan="8">size</td>
		<td>0000</td>
		<td rowspan="8">Fc</td>
		<td>add(size)(/q1) Fa,Fb,Fc</td>
	</tr>
	<tr>
		<td>0001</td>
		<td>sub(size)(/q1) Fa,Fb,Fc</td>
	</tr>
	<tr>
		<td>0010</td>
		<td>mul(size)(/q1) Fa,Fb,Fc</td>
	</tr>
	<tr>
		<td>0011</td>
		<td>div(size)(/q1) Fa,Fb,Fc</td>
	</tr>
	<tr>
		<td>0100</td>
		<td>cmpxun(size)/(q1) Fa,Fb,Fc</td>
	</tr>
	<tr>
		<td>0101</td>
		<td>cmpxeq(size)/(q1) Fa,Fb,Fc</td>
	</tr>
	<tr>
		<td>0110</td>
		<td>cmpxlt(size)/(q1) Fa,Fb,Fc</td>
	</tr>
	<tr>
		<td>0111</td>
		<td>cmpxle(size)/(q1) Fa,Fb,Fc</td>
	</tr>
	<tr>
		<td colspan="6" rowspan="4">-</td>
		<td>1000</td>
		<td rowspan="4">-</td>
		<td rowspan="4">reserved</td>
	</tr>
	<tr>
		<td>1001</td>
	</tr>
	<tr>
		<td>1010</td>
	</tr>
	<tr>
		<td>1011</td>
	</tr>	
	<tr>
		<td>11111</td>
		<td>Fb</td>
		<td>trap</td>
		<td colspan="2">round</td>
		<td>size</td>
		<td>1100</td>
		<td>Fc</td>
		<td>cvt(size)s/(q1) Fa,Fb,Fc</td>
	</tr>	
	<tr>
		<td colspan="6">-</td>
		<td>1101</td>
		<td>-</td>
		<td>reserved</td>
	</tr>	
	<tr>
		<td rowspan="2">11111</td>
		<td rowspan="2">Fb</td>
		<td rowspan="2">trap</td>
		<td rowspan="2" colspan="2">round</td>
		<td rowspan="2">size</td>
		<td>1110</td>
		<td rowspan="2">Fc</td>
		<td>cvt(size)t/(q1) Fa,Fb,Fc</td>
	</tr>	
	<tr>
		<td>1111</td>
		<td>cvt(size)q/(q1) Fa,Fb,Fc</td>
	</tr>
</table>


010100aaaaabbbbbuuu00000100ccccc itofs (regs?)
010100aaaaabbbbbuuu00010100ccccc itoff (regs?)
010100aaaaabbbbbuuu00100100ccccc itoft (regs?)



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
