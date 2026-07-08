# ISA Documentation

## format

`0 MM I OOOO DDDD AAAA bbbb BBBB bbbb bbbb`

|symbol|meaning|num bits|
|---|---|---|
|0|constant 0|1|
|MM|Mode|2|
|I|Immediate|1|
|OOOO|Opcode|4|
|DDDD|Destination register address|4|
|AAAA|Operand A register address|4|
|BBBB|Operand B register address|4|
|bBbb|Immediate operand|16|

## Mode (M)

|bits|mode|
|---|---|
|00|IO|
|01|ALU|
|10|JMP|
|11|MEM|

## Immediate (I)

If this value is high the full 16 bit immediate value `bbbb BBBB bbbb bbbb` is used as the second operand of an operation.\
If this bit is low, the operant gets fetched from the register at address BBBB and bits at lowercase b should be set to 0

note: wasted space when immediate b is low, this may change in the future

## Registers (D/A/B)

|name|type|description|
|r0|zero register|voids inputs, always outputs 0 on read|
|r1-13|gp|contains general data for the cpu|
|r14|flags|contains flags for JMP opcodes (see section JMP)|
|r15|sp|current 16 bit stack pointer|

while r14/r15 are technically general purpose registers (only r0 is hardwired to 0), write or reinterpret these registers at your own risk.

## Opcodes (O)

### IO

|opcode|mnemonic|descriptoin|
|---|---|---|
|0000|NOP|no operation|
|0001|CLK|get PC of the current executing (not fetching) instruction|
|0010|IN|read from IO device|
|0011|OUT|Write to IO device|
|0100|STS|Read status from IO device|
|0101|DEV|select IO device (8 bits)|
|0110|||
|0111|||
|1000|||
|1001|||
|1010|||
|1011|||
|1100|||
|1101|||
|1110|||
|1111|||

### ALU

|opcode|mnemonic|descriptoin|
|---|---|---|
|0000|NAND|`~(a&b)`|
|0001|OR|`(a\|b)`|
|0010|AND|`(a&b)`|
|0011|NOR|`~(a\|b)`|
|0100|ADD|`a+b`|
|0101|SUB|`a-b`|
|0110|XOR|`a^b`|
|0111|LSL|`a<<b (logical)`|
|1000|LSR|`a>>b (logical)`|
|1001|CMP|Compare\*|
|1010|MUL|`a*b`|
|1011|||
|1100|||
|1101|||
|1110|||
|1111|||

* note that only ALU instructions can run on pipeline 2 and never generates hazard

* dev note: multiply instruction is currently not pipelined

### Compare

Compare outputs as follow
bit 0 = `(a==b)` \
bit 1 = `(a<b)` unsigned\
bit 2 = `(a<b)` signed\

### JMP

jump directly maps opcode to bits in `arg_a` such that, for the 3 low bits of data (and opcode)

opcode == arg\_a (bitwise) or inverted by opcode's high bit resulting in the below table

|opcode[3]|opcode[2:0]|mnemonic|description|
|---|---|---|---|
|0|000|SSNOP|never jump, hard nop due to generated hazard|
|1|000|JMP|always jump|
|0|001|JEQ|jump if equal|
|1|001|JNE|jump if not equal|
|0|010|JLT|jump less than (unsigned)|
|1|010|JGE|jump greater than or equal (unsigned)|
|0|011|JLE|jump less than or equal (unsigned)|
|1|011|JGT|jump greater than (unsigned)|
|0|100|JLT.S|jump less than (signed)|
|1|100|JGE.S|jump greater than or equal (signed)|
|0|101|JLE.S|jump less than or equal (signed)|
|1|101|JGT.S|jump greater than (signed)|

* note that JMP instructions are a much larger hazard and will always stall other pipelines

* when a jump is taken the pipeline gets flushed by tying all destination addresses to 0. for 2 cycles all instructions currently in the pipeline are converted to NOP (all 0) while the pipeline is being filled again.

### MEM

MEM type operations directly interract with memory and secondary storage
note that the stack resides at the end of program memory (the storage device, not right after program memory). Stack pointer starts at the last byte of memory and decreases as the stack grows.

opcode gets split into 2 parts, high bits correspond to device select while low bits correspond to operation select

|opcode[3:2]|opcode[1:0]|mnemonic|description|
|---|---|---|---|
|00|00|LD|load 16 bits from memory into a register|
|00|01|STR|store a register value in 16 bits of memory|
|00|10||not implemented|
|00|11||not implemented|
|01|00|LD.P|load 16 bits from persistent storage into a register|
|01|01|STR.P|store a register value in 16 bits of persistent storage|
|01|10||not implemented|
|01|11||not implemented|

* note: due to no proper reset .. yet, persistent storage is not actually persistent

## Devices

Device IDs are hardcoded into the fpga fabric, despite hardcoding and somewhat limited Opcode space in instructions it is still possible to select a large amount of devices. Current implementation supports up to 256 devices at 8 bits of device address but may support up to 16 bits (to update in controller).

|ID|Name|
|---|---|
|0x0000|serial uart bridge (115200 baud)|

### UART

The uart bridge is an 8 bit (low byte of data) device at a baud rate of 115200.

It has a single byte of read/write buffer (i.e. cannot "bank" 2 bytes for either operations)
as the cpu is *much* faster than the UART channel 1 byte is considered acceptable.

This device is physically connected to the micro-usb rx/tx channel

|status bit|meaning|info|
|---|---|---|
|0|clear to send|high when a new value can be put on the channel|
|1|recieved data waiting (to be read by cpu)|high when a value is available|

## Accidental instructions

due to formatting of instructions and consequent processing of said instructions it is possible for non ALU instructions (of which the most relevant being JMP mode instructions) to write a value to the register even though we're not in a writing mode. This is because the register file does not differentiate what or who writes to the shared data bus. Usually this behaviour is desired for memory/io instructions that read data (driven zero for writes). In JMP instructions this is usually not desired, and therefore instructions should tie destination to r0 to void the bus data.

If desired developer can compress code in the following format into a single jump instruction with rd set.

```asm
mov rd, arb_b
jxx arg_b
```

Note that there's an exception where rd = r14 due to the jump instruction not receiving the jump flags in time and should be read as fully independent instructions in the same clock cycle.

A small change to the data bus can be made such that jump address is not put on the data bus but instead routed directly to the PC, freeing the bus up for the ALU instead. This would caus Jump instructions to allow side effects mapped 1:1 by to an ALU opcode.

Similar hacks can be produced with mem/io instructions using their bus-driven data.

## Mnemonic Summary

register b or immediate shortened to `B(meaning)`

* all (non cmp) ALU operations assume format `mnemonic rd, ra, B`
* compare mnemonic is used as `CMP ra, B` and stores to r14 in standard assembler
* all jump instructions assume `jxx [label, immediate or register value]`

|mode|0000|0001|0010|0011|0100|0101|0110|0111|1000|1001|1010|1011|1100|1101|1110|1111|
|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|
|00|NOP|CLk rd|IN rd|OUT B(data)|STS rd|DEV B(device ID)|||||||||||
|01|NAND|OR|AND|NOR|ADD|SUB|XOR|LSL|LSR|CMP|MUL||||||
|10|SSNOP|JEQ|JLT|JLE|JLT.S|JLE.S|||JMP|JNE|JGE|JGT|JGE.S|JGT.S|||
|11|LD rd, B(address)\>|STR ra, B(address)|LD.P rd, B(address)\>|STR.P ra, B(address)|||||||||||||

### pseudo instructions

<!-- markdownlint-disable MD033 -->
|mnemonic|from instruction(s)|
|MOV rd, B|add rd, zr, B|
|HLT|.label halt\_addr<br/>jmp halt\_addr|
<!-- markdownlint-disable MD033 -->

## Directives

This assembler exposes a couple directives to handle layout and sanity

|implemented|directive|description|
|---|---|---|
|&check;|.org [address literal]|following lines start layout at [address literal]|
|&check;|section [.text,.data,.bss,.vector]|start of a logical section, used for merging sections into one block|
|&check;|.label [name]|defines a label at this line|
|&check;|.macro [name]|starts a macro definition, cannot start a macro within a macro|
|&check;|.endmacro|ends the current macro definition|
|&check;|%macro [name]|call the macro named [name], arguments not supported|
|&check;|.align [align value]|align the following lines such that address is a multiple of [align value]|
|&check;|.raw|write raw bytes|
|&check;|.text|write a string literal (lower 8 bits per memory address)|
|&cross;|.include [filename]|inject another file's content here (note: may be reordered due to it's sections, macros etc)|
|&cross;|.repeat [n]|repeat next line n times|

note: bytes in .raw directives will left-pad with zeroes to fill whole words when 1/3/5/etc bytes are input, this is because
otherwise instruction addresses cannot be computed properly in this 16-bit architecture

## Hazards

some combination of instructions in the pipeline causes hazards slowing overall execution.
note that no reordering occurs to resolve these hazards.

when a hazard is detected NOP is inserted into the second pipeline to resolve this hazard causing only 1 instruction instead of 2 to be executed.
when a hazard is detected the PC only steps 1 instruction rather than 2.

|hazard|caused by|
|---|---|
|not alu|caused when the second fetched instruction is not an ALU instruction|
|jmp|caused when a jump instruction is the first instruction|
|RAW|caused when instruction 2 (ra or rb) depends on rd of instruction 1|
