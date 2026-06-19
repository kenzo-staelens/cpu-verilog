//~ `New testbench
`timescale  1ns / 1ps

module tb_Clock_wrapper;

// Clock_wrapper Parameters
parameter PERIOD      = 10;
parameter INST_SIZE   = 4 ;
parameter WORD_WIDTH  = 16;

localparam INSTRUCTION_BITS = 8*INST_SIZE;

// Clock_wrapper Inputs
reg   clk                                  = 0 ;
reg   rst                                  = 0 ;
reg   [2*INSTRUCTION_BITS-1:0]  inst64     = 0 ;
reg   jmp                                  = 0 ;
reg   [WORD_WIDTH-1:0]  jmp_addr           = 0 ;

// Clock_wrapper Outputs
wire  [WORD_WIDTH-1:0]  pc_read            ;
wire  ready                                ;
wire  [INSTRUCTION_BITS-1:0]  inst_a       ;
wire  [INSTRUCTION_BITS-1:0]  inst_b       ;


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

initial
begin
    #(PERIOD*2) rst  =  1;
end

Clock_wrapper #(
    .INST_SIZE  ( INST_SIZE  ),
    .WORD_WIDTH ( WORD_WIDTH ))
 u_Clock_wrapper (
    .clk                     ( clk                                ),
    .rst                     ( rst                                ),
    .inst64                  ( inst64    [2*INSTRUCTION_BITS-1:0] ),
    .jmp                     ( jmp                                ),
    .jmp_addr                ( jmp_addr  [WORD_WIDTH-1:0]         ),

    .pc_read                 ( pc_read   [WORD_WIDTH-1:0]         ),
    .ready                   ( ready                              ),
    .inst_a                  ( inst_a    [INSTRUCTION_BITS-1:0]   ),
    .inst_b                  ( inst_b    [INSTRUCTION_BITS-1:0]   )
);

initial
begin
    clk = 0;
    rst = 0;
    
    #10
    rst = 1;

    #20
    rst = 0;
    inst64 = 64'h2012030020230400;
    
    #30
    inst64 = 64'h2012030000230400;

    #40
    jmp =1;
    inst64 = 64'h2012030020230400;

    #60;
    $finish;
end

initial
begin
    $monitor("clk = %b, rst = %b, inst64 = %h, jmp = %b, jmp_addr = %b, pc_read = %b, ready = %b, inst_a = %b, inst_b = %b", clk, rst, inst64, jmp, jmp_addr, pc_read, ready, inst_a, inst_b);
end

`define assert(signal, value, x) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal != value for x "); \
            $finish; \
        end

endmodule