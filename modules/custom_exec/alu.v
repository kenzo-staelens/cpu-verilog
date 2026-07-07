module ALU #(
    parameter WORD_WIDTH = 16
) (
    input clk, // only exists here for multiplier
    input [3:0] opcode,
    input [WORD_WIDTH-1:0] arg_a,
    input [WORD_WIDTH-1:0] arg_b,
    output [WORD_WIDTH-1:0] out
);

    wire [WORD_WIDTH-1:0] cmp;

    // optional: future multiply optimization for warnings
    (* mult_style = "pipe_none", use_dsp = "yes" *) wire [WORD_WIDTH-1:0] multiply_wire;
    assign multiply_wire = arg_a[7:0]*arg_b[7:0];
    // there's no reason to compute 16bx16b = 32b
    // if we're only reading the bottom 16 bits
    // better to just constrain to 8bx8b = 16b and save timing

    // CMP flags = 3 bits
    assign cmp[WORD_WIDTH-1:3]=0;
    assign cmp[0] = (arg_a==arg_b);
    assign cmp[1] = arg_a<arg_b;
    assign cmp[2] = ($signed(arg_a) < $signed(arg_b));

    // Combinational ALU function – uses a case for parallel mux inference
    function [WORD_WIDTH-1:0] alu_out;    // WIDTH should match the size of arg_a/arg_b
        input [3:0] opcode;
        input [WORD_WIDTH-1:0] arg_a, arg_b, cmp, multiply_wire;
        begin
            case (opcode)
                4'b0000: alu_out = ~(arg_a & arg_b);   // NAND
                4'b0001: alu_out = arg_a | arg_b;      // OR
                4'b0010: alu_out = arg_a & arg_b;      // AND
                4'b0011: alu_out = ~(arg_a | arg_b);   // NOR
                4'b0100: alu_out = arg_a + arg_b;      // ADD
                4'b0101: alu_out = arg_a - arg_b;      // SUB
                4'b0110: alu_out = arg_a ^ arg_b;      // XOR
                4'b0111: alu_out = arg_a << arg_b;     // LSL
                4'b1000: alu_out = arg_a >> arg_b;     // LSR
                4'b1001: alu_out = cmp;                // CMP
                4'b1010: alu_out = multiply_wire;      // MUL
                default: alu_out = 0;      // all others → 0
            endcase
        end
    endfunction
    
    // Continuous assignment using the function (no reg needed for out)
    assign out = alu_out(opcode, arg_a, arg_b, cmp, multiply_wire);

endmodule
