//~ `New testbench
`timescale  1ns / 1ps

module tb_Pipeline;

// Pipeline Parameters
parameter PERIOD      = 10;
parameter WORD_WIDTH  = 16;
parameter INST_SIZE   = 4 ;
parameter REGISTER_BITS = 4;

localparam INSTRUCTION_BITS = INST_SIZE*8;

// Pipeline Inputs
reg   clk                                  = 0 ;
reg   rst                                  = 0 ;
reg   [INSTRUCTION_BITS-1:0]  inst         = 0 ;
reg   [WORD_WIDTH-1:0]  data_a             = 0 ;
reg   [WORD_WIDTH-1:0]  data_b             = 0 ;

// Pipeline Outputs
wire  [REGISTER_BITS-1:0]  addr_data_a        ;
wire  [REGISTER_BITS-1:0]  addr_data_b        ;
wire  [1:0]  mode_exec                     ;
wire  [REGISTER_BITS-1:0]  opcode_exec     ;
wire  [REGISTER_BITS-1:0]  dst_exec        ;
wire  [WORD_WIDTH-1:0]  arg_a_exec         ;
wire  [WORD_WIDTH-1:0]  arg_b_exec         ;


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

initial
begin
    #(PERIOD*2) rst  =  1;
end

Pipeline #(
    .WORD_WIDTH ( WORD_WIDTH ),
    .INST_SIZE  ( INST_SIZE  ),
    .REGISTER_BITS ( REGISTER_BITS))
 u_Pipeline (
    .clk                     ( clk                                 ),
    .rst                     ( rst                                 ),
    .inst                    ( inst         [INSTRUCTION_BITS-1:0] ),
    .data_a                  ( data_a       [WORD_WIDTH-1:0]       ),
    .data_b                  ( data_b       [WORD_WIDTH-1:0]       ),

    .addr_data_a             ( addr_data_a  [REGISTER_BITS-1:0]       ),
    .addr_data_b             ( addr_data_b  [REGISTER_BITS-1:0]       ),
    .mode_exec               ( mode_exec    [1:0]                  ),
    .opcode_exec             ( opcode_exec  [REGISTER_BITS-1:0]    ),
    .dst_exec                ( dst_exec     [REGISTER_BITS-1:0]    ),
    .arg_a_exec              ( arg_a_exec   [WORD_WIDTH-1:0]       ),
    .arg_b_exec              ( arg_b_exec   [WORD_WIDTH-1:0]       )
);

initial
begin
    #10
    rst = 1;
    data_a = 16'h1111;
    data_b = 16'h2222;

    #20
    rst = 0;
    
    #40
    inst = 32'h31236789;

    #80
    inst = 32'h21236789;


    #100
    $finish;
end

initial begin
    $monitor("%5d rst = %b, clk = %b, inst=%h, intermediate=%h, addr_a = %h, addr_b = %h, \n| mode = %b, opcode=%h, dst=%h, arg_a=%h, arg_b=%h \n| mode = %b, opcode=%h, dst=%h, arg_a=%h, arg_b=%h",
        $time, clk, rst, inst, u_Pipeline.intermediate,
        addr_data_a, addr_data_b,
        u_Pipeline.mode, u_Pipeline.opcode, u_Pipeline.dst, u_Pipeline.data_a, u_Pipeline.data_b_int,
        mode_exec, opcode_exec, dst_exec, arg_a_exec, arg_b_exec
    );

    end

endmodule