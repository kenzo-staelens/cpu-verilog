module Clock #(
    parameter WORD_WIDTH = 16,
    parameter INST_SIZE = 2
) (
    input clk,
    input rst,
   
    input exec_a,
    input exec_b,
    input jmp,
    input [WORD_WIDTH-1:0] jmp_addr,

    output [WORD_WIDTH-1:0] out
);
    reg [WORD_WIDTH-1:0] int;
    wire [WORD_WIDTH-1:0] store_data;
    wire [$clog2(2*INST_SIZE+1)-1:0] adder_const;

    assign store_data = (jmp) ? jmp_addr : int+adder_const;
    assign out = store_data;

    assign adder_const = (exec_a + exec_b) * INST_SIZE;

    always @ (posedge clk) begin
        if (rst) begin
            int <= {WORD_WIDTH{1'b0}};
        end else begin
            if (jmp | exec_a | exec_b) begin
                int <= store_data;
            end
        end
    end

    initial begin
        int = 0;
    end

endmodule
