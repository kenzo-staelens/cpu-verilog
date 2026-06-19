`define hazard_type Hazard32
module Clock_wrapper #(
    parameter INST_SIZE = 4,
    parameter WORD_WIDTH = 16
) (
    input clk,
    input rst,
    input [2*INSTRUCTION_BITS-1:0] inst64,
    input jmp,
    input [WORD_WIDTH-1:0] jmp_addr,

    output [WORD_WIDTH-1:0] pc_read,
    output ready,
    output [INSTRUCTION_BITS-1:0] inst_a,
    output [INSTRUCTION_BITS-1:0] inst_b
);

    localparam INSTRUCTION_BITS = INST_SIZE*8;

    wire hazard_out;
    wire stall;
    wire do_jmp;

    // little awkward to paremeter for now? -> hazard is fairly implementation specific
    `hazard_type hazard_module (.inst_a(inst64[2*INSTRUCTION_BITS-1:INSTRUCTION_BITS]), .inst_b(inst64[INSTRUCTION_BITS-1:0]), .exec_b(hazard_out));
    Clock # (.WORD_WIDTH(WORD_WIDTH), .INST_SIZE(INST_SIZE)) program_counter (.clk(clk), .rst(rst), .exec_a(1'b1), .exec_b(hazard_out),.jmp(do_jmp), .jmp_addr(jmp_addr), .out(pc_read));
    Clock_busy busy_module(.clk(clk), .rst(rst), .in(do_jmp), .out(stall));


    assign ready = !stall;
    assign inst_a = inst64[2*INSTRUCTION_BITS-1:INSTRUCTION_BITS];
    assign do_jmp = jmp & !stall;
    assign inst_b = (hazard_out == 1'b0) ? inst64[INSTRUCTION_BITS-1:0] : {INSTRUCTION_BITS{1'b0}};
    
endmodule