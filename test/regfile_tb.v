//~ `New testbench
`timescale  1ns / 1ps

module tb_RegFile;

// RegFile Parameters
parameter PERIOD         = 10;
parameter REGISTER_BITS  = 4 ;
parameter WORD_WIDTH      = 16;
parameter MEM_FILE       = "";

// RegFile Inputs
reg   clk                                  = 0 ;
reg   rst                                  = 0 ;
reg   write_enable_1                       = 0 ;
reg   [REGISTER_BITS-1:0]  write_address_1 = 0 ;
reg   [WORD_WIDTH-1:0]  write_data_1        = 0 ;
reg   write_enable_2                       = 0 ;
reg   [REGISTER_BITS-1:0]  write_address_2 = 0 ;
reg   [WORD_WIDTH-1:0]  write_data_2        = 0 ;
reg   [4*REGISTER_BITS-1:0]  output_address_bus = 0 ;
reg   [REGISTER_BITS-1:0]  peek_address    = 0 ;
wire   [WORD_WIDTH-1:0]  peek_out ;



initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

initial
begin
    #(PERIOD*2) rst  =  1;
    #(PERIOD*2+5) rst  =  0;
end

RegFile #(
    .REGISTER_BITS ( REGISTER_BITS ),
    .WORD_WIDTH     ( WORD_WIDTH     ),
    .MEM_FILE      ( MEM_FILE      ))
 u_RegFile (
    .clk                                               ( clk                                                                     ),
    .rst                                               ( rst                                                                     ),
    .write_enable_1                                    ( write_enable_1                                                          ),
    .write_address_1                                   ( write_address_1                                   [REGISTER_BITS-1:0]   ),
    .write_data_1                                      ( write_data_1                                      [WORD_WIDTH-1:0]       ),
    .write_enable_2                                    ( write_enable_2                                                          ),
    .write_address_2                                   ( write_address_2                                   [REGISTER_BITS-1:0]   ),
    .write_data_2                                      ( write_data_2                                      [WORD_WIDTH-1:0]       ),
    .output_address_bus                                ( output_address_bus                                [4*REGISTER_BITS-1:0] ),
    .peek_address                                      ( peek_address                                      [REGISTER_BITS-1:0]   ),
    .peek_out                                          ( peek_out                                          [WORD_WIDTH-1:0]       )
);

initial
begin
    $monitor("clk = %3d, rst=%b", clk, rst);
    #30
    write_enable_1 = 1;
    write_address_1 = 4'b0001;
    write_data_1 = 16'h5555;
    write_enable_2 = 1;
    write_address_2 = 4'b0010;
    write_data_2 = 16'haaaa;
    peek_address = 4'b0010;

    #40
    $display("%4h %4h %4h %4h", u_RegFile.storage[0], u_RegFile.storage[1], u_RegFile.storage[2], u_RegFile.storage[3]);
    $display("%4h %4h %4h %4h", u_RegFile.storage[4], u_RegFile.storage[6], u_RegFile.storage[6], u_RegFile.storage[7]);
    $display("%4h %4h %4h %4h", u_RegFile.storage[8], u_RegFile.storage[9], u_RegFile.storage[10], u_RegFile.storage[11]);
    $display("%4h %4h %4h %4h", u_RegFile.storage[12], u_RegFile.storage[13], u_RegFile.storage[14], u_RegFile.storage[15]);
    $display("%4h", peek_out);
    #45
    $finish;
end

endmodule