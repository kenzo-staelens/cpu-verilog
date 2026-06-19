module PersistentBRAM # (
    parameter WORD_WIDTH = 16,
    parameter ADDRESS_WIDTH = 8
) (
    input clk,
    input stall,
    input write_enable,
    input read_enable,
    input [ADDRESS_WIDTH-1:0] addr_data,
    input [WORD_WIDTH-1:0] data_in,
    output [WORD_WIDTH-1:0] data_out
);

    localparam  BANK_WIDTH = (2**(ADDRESS_WIDTH));
    wire [ADDRESS_WIDTH-1:0] actual_address = addr_data[ADDRESS_WIDTH-1:0];

    (* ram_style = "block" *) reg [WORD_WIDTH-1:0] ram [0:BANK_WIDTH-1];
    reg [WORD_WIDTH-1:0] outreg;

    integer i;
    initial begin
        for (i=0; i<BANK_WIDTH; i = i + 1) begin
            ram[i]<=0;
        end
        outreg <= 0;
    end

    always @(posedge clk) begin
        if (!stall) begin
            if (write_enable) ram[actual_address] <= data_in;
            outreg <= (read_enable) ? ram[actual_address] : {WORD_WIDTH{1'b0}};
        end
    end

    assign data_out = outreg;
endmodule
