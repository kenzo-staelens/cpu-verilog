module DelayLine # (
    parameter WORD_WIDTH = 1
) (
    input clk,
    input rst,
    input [WORD_WIDTH-1:0] in,
    output reg [WORD_WIDTH-1:0] out
);
    always @(posedge clk) begin
        if (rst)
            out <= {WORD_WIDTH{1'b0}};
        else
            out <= in;
    end

    initial
    begin
        out = 0;
    end
endmodule
