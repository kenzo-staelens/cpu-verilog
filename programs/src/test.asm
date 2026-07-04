section .text
mov r1, 0x000F
mov flags, 0x1
jeq test
mov r2, 0x00F0
.label test
mov r3, 0x0F00
hlt
mov r4, 0xF000