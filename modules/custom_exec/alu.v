module ALU #(
    parameter WORD_WIDTH = 16
) (
    input [3:0] opcode,
    input [WORD_WIDTH-1:0] arg_a,
    input [WORD_WIDTH-1:0] arg_b,
    output [WORD_WIDTH-1:0] out
);

    wire [WORD_WIDTH-1:0] cmp;
    // CMP flags = 3 bits
    assign cmp[WORD_WIDTH-1:3]=0;
    assign cmp[0] = (arg_a==arg_b);
    assign cmp[1] = arg_a<arg_b;
    assign cmp[2] = ($signed(arg_a) < $signed(arg_b));

    assign out = (opcode == 4'b0000) ? ~(arg_a & arg_b) :  // 0 NAND
                 (opcode == 4'b0001) ? arg_a | arg_b    :  // 1 OR
                 (opcode == 4'b0010) ? arg_a & arg_b    :  // 2 AND
                 (opcode == 4'b0011) ? ~(arg_a | arg_b) :  // 3 NOR
                 (opcode == 4'b0100) ? arg_a + arg_b    :  // 4 ADD
                 (opcode == 4'b0101) ? arg_a - arg_b    :  // 5 SUB
                 (opcode == 4'b0110) ? arg_a ^ arg_b    :  // 6 XOR
                 (opcode == 4'b0111) ? arg_a << arg_b   :  // 7 LSL
                 (opcode == 4'b1000) ? arg_a >> arg_b   :  // 8 LSR
                 (opcode == 4'b1001) ? cmp              :  // 9 CMP
                 (opcode == 4'b1010) ? arg_a * arg_b    :  // 10 MUL
                                  0; // default

endmodule
