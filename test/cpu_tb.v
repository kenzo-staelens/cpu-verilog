`timescale  1ps / 1ps

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
// reg   rst                                  = 1 ;
reg   [15:0] tick                          = 0 ;
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



CPU #(
    .INST_SIZE          ( INST_SIZE          ),
    .WORD_WIDTH         ( WORD_WIDTH         ),
    .REGISTER_BITS      ( REGISTER_BITS      ),
    .RAM_ADDR_WIDTH     ( RAM_ADDR_WIDTH     ),
    .PERSIST_ADDR_WIDTH ( PERSIST_ADDR_WIDTH ))
 u_CPU (
    .clk                           ( clk                                               ),
    // .rst                           ( rst                                               ),
    .peek_address                  ( peek_address                  [REGISTER_BITS-1:0] ),
    .incoming_io                   ( incoming_io                   [WORD_WIDTH-1:0]    ),

    .peek_out                      ( peek_out                      [WORD_WIDTH-1:0]    ),
    .opcode                        ( opcode                        [3:0]               ),
    .ctrl_en_io                    ( ctrl_en_io                                        ),
    .outgoing_io                   ( outgoing_io                   [WORD_WIDTH-1:0 ]   )
);

initial begin

forever #10
    $display("inst64 = %h\n    regfile\n\t%h %h %h %h %h %h %h %h\n\t%h %h %h %h\n    pipeline\n\tinternal = %h\n\tb_internal = %h\n\tmode = %b\n\topcode = %h\n\ta_exec = %h\n\tb_exec = %h\n\tdst_1 = %h\n    control\n\tdata_bus = %h\n\talu_1 = %h\n\talu_2 = %h\n\tnext_pc = %h\n\tprogram_we = %b\n\treg_addr_a = %h\n\taddr_data=%h\n\tdata_in=%h",//\n    mem\n\tram[28] = %h\n\tram[32] = %h\n\tram[33] = %h\n\tram[36] = %h\n\tram[37] = %h",
    // rst,
    u_CPU.inst64,
    u_CPU.register_file.storage[0],
    u_CPU.register_file.storage[1],
    u_CPU.register_file.storage[2],
    u_CPU.register_file.storage[3],
    u_CPU.register_file.storage[4],
    u_CPU.register_file.storage[5],
    u_CPU.register_file.storage[6],
    u_CPU.register_file.storage[7],
    0, // u_CPU.register_file.data_1,
    0, // u_CPU.register_file.data_2,
    0, // u_CPU.register_file.data_3,
    0, // u_CPU.register_file.data_4,
    u_CPU.pipeline_1.intermediate,
    u_CPU.pipeline_1.data_b_int,
    u_CPU.pipeline_1.mode_exec,
    u_CPU.pipeline_1.opcode_exec,
    u_CPU.pipeline_1.arg_a_exec,
    u_CPU.pipeline_1.arg_b_exec,
    u_CPU.dst_1,
    u_CPU.data_bus,
    u_CPU.alu_out_1,
    u_CPU.alu_out_2,
    u_CPU.program_address,
    u_CPU.progmem_we,
    u_CPU.pipeline_1.reg_addr_a,
    u_CPU.progmem.addr_data,
    u_CPU.progmem.data_in,
    // u_CPU.progmem.gen_banks[4].ram[3],// u_CPU.progmem.ram[28],
    // u_CPU.progmem.gen_banks[0].ram[4], // u_CPU.progmem.ram[32],
    // u_CPU.progmem.gen_banks[1].ram[4], // u_CPU.progmem.ram[33],
    // u_CPU.progmem.gen_banks[4].ram[4], // u_CPU.progmem.ram[36],
    // u_CPU.progmem.gen_banks[5].ram[4], // u_CPU.progmem.ram[37],
);
// $display("ram_content\n\t%h %h %h %h %h %h %h %h\n\t%h %h %h %h %h %h %h %h\n\t%h %h %h %h %h %h %h %h\n\t%h %h %h %h %h %h %h %h\n\t%h %h %h %h %h %h %h %h",
//     u_CPU.progmem.gen_banks[0].ram[0],
//     u_CPU.progmem.gen_banks[1].ram[0],
//     u_CPU.progmem.gen_banks[2].ram[0],
//     u_CPU.progmem.gen_banks[3].ram[0],
//     u_CPU.progmem.gen_banks[4].ram[0],
//     u_CPU.progmem.gen_banks[5].ram[0],
//     u_CPU.progmem.gen_banks[6].ram[0],
//     u_CPU.progmem.gen_banks[7].ram[0],
//     u_CPU.progmem.gen_banks[0].ram[1],
//     u_CPU.progmem.gen_banks[1].ram[1],
//     u_CPU.progmem.gen_banks[2].ram[1],
//     u_CPU.progmem.gen_banks[3].ram[1],
//     u_CPU.progmem.gen_banks[4].ram[1],
//     u_CPU.progmem.gen_banks[5].ram[1],
//     u_CPU.progmem.gen_banks[6].ram[1],
//     u_CPU.progmem.gen_banks[7].ram[1],
//     u_CPU.progmem.gen_banks[0].ram[2],
//     u_CPU.progmem.gen_banks[1].ram[2],
//     u_CPU.progmem.gen_banks[2].ram[2],
//     u_CPU.progmem.gen_banks[3].ram[2],
//     u_CPU.progmem.gen_banks[4].ram[2],
//     u_CPU.progmem.gen_banks[5].ram[2],
//     u_CPU.progmem.gen_banks[6].ram[2],
//     u_CPU.progmem.gen_banks[7].ram[2],
//     u_CPU.progmem.gen_banks[0].ram[3],
//     u_CPU.progmem.gen_banks[1].ram[3],
//     u_CPU.progmem.gen_banks[2].ram[3],
//     u_CPU.progmem.gen_banks[3].ram[3],
//     u_CPU.progmem.gen_banks[4].ram[3],
//     u_CPU.progmem.gen_banks[5].ram[3],
//     u_CPU.progmem.gen_banks[6].ram[3],
//     u_CPU.progmem.gen_banks[7].ram[3],
//     u_CPU.progmem.gen_banks[0].ram[4],
//     u_CPU.progmem.gen_banks[1].ram[4],
//     u_CPU.progmem.gen_banks[2].ram[4],
//     u_CPU.progmem.gen_banks[3].ram[4],
//     u_CPU.progmem.gen_banks[4].ram[4],
//     u_CPU.progmem.gen_banks[5].ram[4],
//     u_CPU.progmem.gen_banks[6].ram[4],
//     u_CPU.progmem.gen_banks[7].ram[4]
// );

end
initial begin
#225 $finish;
end
endmodule
