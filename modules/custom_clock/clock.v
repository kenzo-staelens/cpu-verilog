module Clock #(
    parameter WORD_WIDTH = 16,
    parameter INST_SIZE = 4
) (
    input clk,
    input rst,
   
    input exec_a,
    input exec_b,
    input jmp,
    input [WORD_WIDTH-1:0] jmp_addr,

    output reg [WORD_WIDTH-1:0] out
);

    wire [WORD_WIDTH-1:0] store_data;
    wire [$clog2(2*INST_SIZE+1)-1:0] adder_const;

    assign store_data = (jmp) ? jmp_addr : out+adder_const;

    assign adder_const = (exec_a + exec_b) * INST_SIZE;

    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            out <= {WORD_WIDTH{1'b0}};
        end else begin
            if (jmp | exec_a | exec_b) begin
                out <= store_data;
            end
        end
    end

    initial begin
        out = 0;
    end

endmodule