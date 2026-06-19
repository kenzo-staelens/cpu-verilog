`timescale  1ns / 1ps

module tb_CPU;

// CPU Parameters
parameter PERIOD              = 10;
parameter INST_SIZE           = 4 ;
parameter WORD_WIDTH          = 16;
parameter REGISTER_BITS       = 4 ;
parameter RAM_ADDR_WIDTH      = 16;
parameter PERSIST_ADDR_WIDTH  = 14;

// CPU Inputs
reg   clk                                  = 0 ;
reg   rst                                  = 1 ;
reg   [REGISTER_BITS-1:0]  peek_address    = 0 ;
reg   [WORD_WIDTH-1:0]  incoming_io        = 0 ;

// CPU Outputs
wire  [WORD_WIDTH-1:0]  peek_out           ;
wire  [3:0]  opcode                        ;
wire  ctrl_en_io                           ;
wire  [WORD_WIDTH-1:0 ]  outgoing_io       ;


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

initial
begin
    #(PERIOD*2) rst  =  0;
end

CPU #(
    .INST_SIZE          ( INST_SIZE          ),
    .WORD_WIDTH         ( WORD_WIDTH         ),
    .REGISTER_BITS      ( REGISTER_BITS      ),
    .RAM_ADDR_WIDTH     ( RAM_ADDR_WIDTH     ),
    .PERSIST_ADDR_WIDTH ( PERSIST_ADDR_WIDTH ))
 u_CPU (
    .clk                           ( clk                                               ),
    .rst                           ( rst                                               ),
    .peek_address                  ( peek_address                  [REGISTER_BITS-1:0] ),
    .incoming_io                   ( incoming_io                   [WORD_WIDTH-1:0]    ),

    .peek_out                      ( peek_out                      [WORD_WIDTH-1:0]    ),
    .opcode                        ( opcode                        [3:0]               ),
    .ctrl_en_io                    ( ctrl_en_io                                        ),
    .outgoing_io                   ( outgoing_io                   [WORD_WIDTH-1:0 ]   )
);

initial begin
    $monitor("rst=%b clk=%b inst64=%h r0=%h r1=%h r2=%h r3=%h r4=%h r5=%h inst_a=%h inst_b=%h pl_1_int=%b b_int=%h b_exec=%h",
    rst, clk, u_CPU.inst64,
    u_CPU.register_file.storage[0],
    u_CPU.register_file.storage[1],
    u_CPU.register_file.storage[2],
    u_CPU.register_file.storage[3],
    u_CPU.register_file.storage[4],
    u_CPU.register_file.storage[5],
    u_CPU.inst_a,
    u_CPU.inst_b,
    u_CPU.pipeline_1.intermediate,
    u_CPU.pipeline_1.data_b_int,
    u_CPU.pipeline_1.arg_b_exec
);
end

initial begin
// add r1, r0, 22081
// add r2, r0, 22098
// str16 r1, 8
// str16 r2, 10
// add r4, r1, 1
// add r5, r2, 2
// add r3, r1, r2
// jmp 32

u_CPU.progmem.gen_banks[0].ram[0] = 16'h5610;
u_CPU.progmem.gen_banks[1].ram[0] = 16'h5641;
u_CPU.progmem.gen_banks[2].ram[0] = 16'h5620;
u_CPU.progmem.gen_banks[3].ram[0] = 16'h5652;
u_CPU.progmem.gen_banks[0].ram[1] = 16'h5110;
u_CPU.progmem.gen_banks[1].ram[1] = 16'h0008;
u_CPU.progmem.gen_banks[2].ram[1] = 16'h5120;
u_CPU.progmem.gen_banks[3].ram[1] = 16'h000A;
u_CPU.progmem.gen_banks[0].ram[2] = 16'h5641;
u_CPU.progmem.gen_banks[1].ram[2] = 16'h0001;
u_CPU.progmem.gen_banks[2].ram[2] = 16'h5652;
u_CPU.progmem.gen_banks[3].ram[2] = 16'h0002;
u_CPU.progmem.gen_banks[0].ram[3] = 16'h4631;
u_CPU.progmem.gen_banks[1].ram[3] = 16'h0200;
u_CPU.progmem.gen_banks[2].ram[3] = 16'h700F;
u_CPU.progmem.gen_banks[3].ram[3] = 16'h0020;
end

initial
begin
    #80
    $finish;
end

endmodule