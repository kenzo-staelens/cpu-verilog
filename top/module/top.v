module Top#(
    REGISTER_BITS = 4,
    WORD_WIDTH = 16
) (
    input clk,
    input [REGISTER_BITS-1:0] peek_address,
    output [WORD_WIDTH-1:0] peek_out
);

    reg [1:0] reset_pulse = 0;
    reg rst = 1;

    always @(posedge clk) begin
        reset_pulse <= reset_pulse+1;
        if (reset_pulse==3) rst<=0;
    end


CPU #(
    .INST_SIZE(2),
    .WORD_WIDTH(WORD_WIDTH),
    .REGISTER_BITS(REGISTER_BITS),
    .RAM_ADDR_WIDTH(16),
    .PERSIST_ADDR_WIDTH(14)
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