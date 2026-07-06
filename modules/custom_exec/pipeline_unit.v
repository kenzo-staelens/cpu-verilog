`define SANITY_MACRO(INCOMING_VALUE, SANITY_VALUE) sanity_check_regbits_``INCOMING_VALUE``_sanity_``SANITY_VALUE`` m();

module Pipeline # (
    parameter WORD_WIDTH = 16,
    parameter INST_SIZE = 4,
    parameter REGISTER_BITS = 4 // number of bits to index a register
) (
    input clk,
    input rst,
    input [INSTRUCTION_BITS-1:0] inst,
    input ready,  // if not -> stall the pipeline (output only)

    // prefetch data "output"
    output [REGISTER_BITS-1:0] reg_addr_a,
    output [REGISTER_BITS-1:0] reg_addr_b,

    
    // incoming prefetched data
    input [WORD_WIDTH-1:0] reg_resp_a,
    input [WORD_WIDTH-1:0] reg_resp_b,


    // execute output
    output [1:0] mode_exec,
    output [REGISTER_BITS-1:0] opcode_exec,
    output [REGISTER_BITS-1:0] dst_exec,
    output [WORD_WIDTH-1:0] arg_a_exec,
    output [WORD_WIDTH-1:0] arg_b_exec
);
    localparam INSTRUCTION_BITS = INST_SIZE *8;
    localparam OPCODE_BITS = 4;

    wire [INSTRUCTION_BITS-1:0] intermediate; // fetch -> decode

    // decode logic
    wire [1:0] mode;
    wire [OPCODE_BITS-1:0] opcode;
    wire [REGISTER_BITS-1:0] dst;
    wire immediate_b;
    wire [WORD_WIDTH-1:0] immediate_value;

    wire _unused_ok = &{intermediate[INSTRUCTION_BITS-1]}; //highest bit unused

    assign {mode, immediate_b, opcode, dst, reg_addr_a, immediate_value} = intermediate[INSTRUCTION_BITS-2:0];  //std -1 and extra -1 for unused highest bit
    assign reg_addr_b = intermediate[8+REGISTER_BITS-1:8];

    // switched data b or immediate
    wire [WORD_WIDTH-1:0] data_b_int = (immediate_b == 1'b1) ? immediate_value : reg_resp_b;

    // fetch delay line
    DelayLine # (.WORD_WIDTH(INSTRUCTION_BITS)) fetch_delay (.clk(clk), .rst(rst), .in(inst), .out(intermediate));
    

    // decode delay lines
    DelayLine # (.WORD_WIDTH(2)) delay_mode (.clk(clk), .rst(rst), .in(mode), .out(mode_exec));
    DelayLine # (.WORD_WIDTH(OPCODE_BITS)) delay_opcode (.clk(clk), .rst(rst), .in(opcode), .out(opcode_exec));
    DelayLine # (.WORD_WIDTH(REGISTER_BITS)) delay_dst (.clk(clk), .rst(rst), .in(dst), .out(dst_exec));
    DelayLine # (.WORD_WIDTH(WORD_WIDTH)) delay_arg_a (.clk(clk), .rst(rst), .in(reg_resp_a), .out(arg_a_exec));
    DelayLine # (.WORD_WIDTH(WORD_WIDTH)) delay_arg_b (.clk(clk), .rst(rst), .in(data_b_int), .out(arg_b_exec));

    //verification macro
    `ifdef __sanity__
    // 0MMI + OOOO + DDDD AAAA
    localparam sanity = 4 + OPCODE_BITS + 2* REGISTER_BITS + WORD_WIDTH;
    generate
        if (INSTRUCTION_BITS != sanity) begin : sanity_check
            `SANITY_MACRO(INSTRUCTION_BITS, sanity)
        end
    endgenerate
    `endif


endmodule