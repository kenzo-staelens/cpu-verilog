add r1, zr, 0x3641
add r2, zr, 0x3652
str r1, 0x10
str r2, 0x12
add r4, r1, 1
add r5, r2, 2
add r3, r1, r2
hlt
.label test
jeq.u test
; test