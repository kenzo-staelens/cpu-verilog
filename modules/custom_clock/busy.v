module Clock_busy (
    input clk,
    input rst,
    input in,
    output out,
    output out_early
);
    wire intermediate;
    wire outwire;

    DelayLine delay1 (.clk(clk), .rst(rst), .in(in & ~out), .out(intermediate));
    DelayLine delay2 (.clk(clk), .rst(rst), .in(intermediate), .out(outwire));
    assign out = intermediate | outwire;
    assign out_early = in | intermediate;
endmodule
