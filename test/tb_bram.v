//~ `New testbench
`timescale  1ns / 1ps

module tb_ProgMemBRAM;

// ProgMemBRAM Parameters
parameter PERIOD      = 10;
parameter WORD_WIDTH  = 16;
parameter NUM_BANKS   = 4 ;

// ProgMemBRAM Inputs
reg   clk                                  = 0 ;
reg   stall                                = 0 ;
reg   write_enable                         = 0 ;
reg   read_enable                          = 0 ;
reg   [WORD_WIDTH-1:0]  addr_data          = 0 ;
reg   [WORD_WIDTH-1:0]  data_in            = 0 ;
reg   [WORD_WIDTH-1:0]  inst_addr          = 0 ;

// ProgMemBRAM Outputs
wire  [WORD_WIDTH-1:0]  data_out           ;
wire  [NUM_BANKS*WORD_WIDTH-1:0]  inst64     ;


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

initial
begin
    #0 stall = 1;
end

ProgMemBRAM #(
    .WORD_WIDTH ( WORD_WIDTH ),
    .NUM_BANKS  ( NUM_BANKS  ))
 u_ProgMemBRAM (
    .clk                     ( clk                                    ),
    .stall                   ( stall                                  ),
    .write_enable            ( write_enable                           ),
    .read_enable             ( read_enable                            ),
    .addr_data               ( addr_data     [WORD_WIDTH-1:0]         ),
    .data_in                 ( data_in       [WORD_WIDTH-1:0]         ),
    .inst_addr               ( inst_addr     [WORD_WIDTH-1:0]         ),

    .data_out                ( data_out      [WORD_WIDTH-1:0]         ),
    .inst64                  ( inst64        [NUM_BANKS*WORD_WIDTH-1:0] )
);

initial
begin
    #10
    $monitor(
        "clk = %b, stall = %b, we = %b, re=%b, addr_data=%h, data_in=%h, data_out=%h, inst_addr=%h, inst64=%h",
        clk, stall, write_enable, read_enable, addr_data, data_in, data_out, inst_addr, inst64,
    );
    stall=0;
    data_in = 2;
    addr_data = 1;
    write_enable = 1;
    #40
    $finish;
end

endmodule