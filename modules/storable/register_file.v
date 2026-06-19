module RegFile #(
    parameter REGISTER_BITS = 4,
    parameter WORD_WIDTH = 16,
    parameter MEM_FILE = ""
) (
    input clk,
    input rst,

    input write_enable_1,
    input [REGISTER_BITS-1:0] write_address_1,
    input [WORD_WIDTH-1:0] write_data_1,

    input write_enable_2,
    input [REGISTER_BITS-1:0] write_address_2,
    input [WORD_WIDTH-1:0] write_data_2,

    input [4*REGISTER_BITS-1:0] output_address_bus,
    output [4*WORD_WIDTH-1:0] output_bus,

    input [REGISTER_BITS-1:0] peek_address,
    output [WORD_WIDTH-1:0] peek_out
);

    (* ram_style = "registers" *) reg [WORD_WIDTH-1:0] storage [0:2**REGISTER_BITS-1];

    integer init_idx;
    initial
    begin
        for (init_idx = 0; init_idx < (2**REGISTER_BITS); init_idx = init_idx + 1)
        begin
            storage[init_idx] = 0;
        end
        if (MEM_FILE!="") $readmemh(MEM_FILE, storage);
    end

    wire data_1 = storage[output_address_bus[4*REGISTER_BITS-1:3*REGISTER_BITS]];
    wire data_2 = storage[output_address_bus[3*REGISTER_BITS-1:2*REGISTER_BITS]];
    wire data_3 = storage[output_address_bus[2*REGISTER_BITS-1:1*REGISTER_BITS]];
    wire data_4 = storage[output_address_bus[1*REGISTER_BITS-1:0]];
    
    assign output_bus = {data_1, data_2, data_3, data_4};
    assign peek_out = storage[peek_address];

    always @(posedge clk) begin
        if (!rst) begin
            if (write_enable_1 && write_address_1 != 0) begin
                storage[write_address_1] <= write_data_1;
            end
            if (write_enable_2 && write_address_2 != 0) begin
                storage[write_address_2] <= write_data_2;
            end
        end
    end

endmodule