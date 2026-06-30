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
|11|STR|

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
|1001|CMP|Compare*|
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

opcode == arg_a (bitwise) or inverted by opcode's high bit resulting in the below table

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

### STR

STR type operations directly interract with memory and secondary storage
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

### Pseudo

Pseudo instructions are a set of additional instructions that can be constructed
using more basic (defined)

<!-- markdownlint-disable MD033 -->
|mnemonic|translates|
|---|---|
|MOV rd, rb|add rd, zr, rb|
|HLT|.label halt_addr<br/>jmp halt_addr|
<!-- markdownlint-enable MD033 -->

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
