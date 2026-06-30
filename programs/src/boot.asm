.macro readwait
    .label 1
    sts r1
    and r1, r1, 0b10
    cmp r1, zr
    jne 1b
    .endmacro
.macro readword
    ; words are 16 bits, 2 bytes, uart only returns 1 byte per request
    ; reads a word into r1, uses r2 as scrap register
    ; load uppper
    %readwait
    in r1
    lsl r1, r1, 8
    ; load lower, merge with r1
    %readwait
    in r2
    or r1, r1, r2
.endmacro
jmp begin_boot

section .text  ; not implemented
.org 0xE000
    .label begin_boot
    ; load "to-read bytes" into r3
    %readword
    mov r3, r1
    mov r4, 0 ; write address
    ; skip if r3 == 0 then just halt
    cmp r3, 0
    jeq zeroload
    .label begin_load
    %readword
    str r3, r4
    sub r3, r3, 1
    add r4, r4, 1
    cmp r3, 0
    jgt begin_load
    jmp 0x00
    .label zeroload
    hlt