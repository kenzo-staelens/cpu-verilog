//~ `New testbench
`timescale  1ns / 1ps

module tb_PersistentBRAM;

// PersistentBRAM Parameters
parameter PERIOD      = 10;
parameter WORD_WIDTH  = 16;

// PersistentBRAM Inputs
reg   clk                                  = 0 ;
reg   stall                                = 0 ;
reg   write_enable                         = 0 ;
reg   read_enable                          = 0 ;
reg   [WORD_WIDTH-1:0]  addr_data          = 0 ;
reg   [WORD_WIDTH-1:0]  data_in            = 0 ;

// PersistentBRAM Outputs
wire  [WORD_WIDTH-1:0]  data_out           ;


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

initial
begin
    #0 stall = 1;
end

PersistentBRAM #(
    .WORD_WIDTH ( WORD_WIDTH ))
 u_PersistentBRAM (
    .clk                     ( clk                            ),
    .stall                   ( stall                          ),
    .write_enable            ( write_enable                   ),
    .read_enable             ( read_enable                    ),
    .addr_data               ( addr_data     [WORD_WIDTH-1:0] ),
    .data_in                 ( data_in       [WORD_WIDTH-1:0] ),

    .data_out                ( data_out      [WORD_WIDTH-1:0] )
);

initial
begin
    #10
    $monitor(
        "clk = %b, stall = %b, we = %b, re=%b, addr_data=%h, data_in=%h, data_out=%h",
        clk, stall, write_enable, read_enable, addr_data, data_in, data_out,
    );
    stall=0;
    data_in = 2;
    addr_data = 1;
    write_enable = 1;
    #11
    write_enable = 0;
    read_enable = 1;
    addr_data = 2;
    #40
    $finish;
end

endmodule