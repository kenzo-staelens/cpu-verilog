; uart sts[0] = clear to send
; uart sts[1] = input waiting

; Read from terminal then echo back the result
.macro writewait
.label 1
sts r1
and r1, r1, 0b01
cmp r1, zr
jeq 1b
.endmacro
.macro readwait
.label 2
sts r1
and r1, r1, 0b10
cmp r1, zr
jeq 2b
.endmacro
section .text
jmp begin
ld r4, 0x1
.label begin
%readwait
in r3
%writewait
out r3
jmp begin
