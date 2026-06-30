; uart sts[0] = clear to send
; uart sts[0] = waiting

; raw output 'AB' to uart terminal, then exit
.macro waitloop
.label 1
sts r1
and r1, r1, 0x01
cmp r1, zr
jne 1b
.endmacro
%waitloop
add r1, zr, 'A'
out r1
%waitloop
add r1, zr, 'B'
hlt
