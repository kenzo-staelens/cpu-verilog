module Top#(
    REGISTER_BITS = 4,
    WORD_WIDTH = 16
) (
    input clk,
    input [REGISTER_BITS-1:0] peek_address,
    output [WORD_WIDTH-1:0] peek_out
);
    wire rst;
    BootModule boot(.clk(clk), .rst_wire(rst));


CPU #(
    .INST_SIZE(2),
    .WORD_WIDTH(WORD_WIDTH),
    .REGISTER_BITS(REGISTER_BITS),
    .RAM_ADDR_WIDTH(16),
    .PERSIST_ADDR_WIDTH(15)
) cpu (
    .rst(rst),
    .clk(clk),
    // additionally used as ready signal from external sources
    // this module runs when reset is low
    .peek_address(peek_address),
    .peek_out(peek_out),

    // export io
    // reserved signals
    // note IO is, in addition to IO signals
    // kind of a trash can for other uncategorized signals
    // 0 = NOP
    // 1 = counter
    .opcode(),
    .ctrl_en_io(),
    .incoming_io(0),
    .outgoing_io()
);
endmodule

module BootModule #(
    parameter PULSES=3
) (
    input clk,
    output rst_wire
);

    assign rst_wire = rst;
    reg [$clog2(PULSES)-1:0] reset_pulse;
    reg rst;

    initial begin
        reset_pulse = 0;
        rst = 1;
    end

    always @(posedge clk) begin
        if (reset_pulse<PULSES) reset_pulse <= reset_pulse+1;
        else rst<=0;
    end
endmodule

