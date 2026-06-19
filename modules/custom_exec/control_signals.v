module ControlExec # (
    parameter WORD_WIDTH = 16
) (
    input [1:0] mode,

    // from compare flag unit
    input [WORD_WIDTH-1:0] jmp_addr,
    input jmp_flag,

    //from alu
    input [WORD_WIDTH-1:0] data_alu,

    //incoming io (only)
    input [WORD_WIDTH-1:0] data_io,

    //external control signals
    output en_jmp,
    output en_store,
    output en_io,

    //outgoing bus
    output [WORD_WIDTH-1:0] data_bus,

    //just to make verilog happy
    input [WORD_WIDTH-1:0] storage_out
);

    assign data_bus = (mode == 2'b00) ? data_io : 
                      (mode == 2'b01) ? data_alu :  
                      (mode == 2'b10) ? jmp_addr :
                      (mode == 2'b11) ? storage_out :
                      {WORD_WIDTH{1'b0}};
                    
    assign en_io = (mode == 2'b00);
    assign en_jmp = (mode == 2'b10) && jmp_flag;
    assign en_store = (mode == 2'b11);
endmodule