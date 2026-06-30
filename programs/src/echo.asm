; uart sts[0] = clear to send
; uart sts[1] = input waiting

; Read from terminal then echo back the result
.org 0x02
.macro writewait
.label 1
sts r1
and r1, r1, 0b01
cmp r1, zr
jne 1b
.endmacro
.macro readwait
.label 1
sts r1
and r1, r1, 0b10
cmp r1, zr
jne 1b
.endmacro
.label begin
%readwait
in r1
%writewait
out r1
jmp begin
