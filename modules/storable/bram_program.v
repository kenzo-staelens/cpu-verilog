module ProgMemBRAM # (
    parameter WORD_WIDTH = 16,
    parameter NUM_BANKS = 4,
    parameter ADDRESS_WIDTH = 16
) (
    input clk,
    input stall,
    input write_enable,
    input read_enable,
    input [WORD_WIDTH-1:0] addr_data,
    input [WORD_WIDTH-1:0] data_in,
    output [WORD_WIDTH-1:0] data_out,

    input [WORD_WIDTH-1:0] inst_addr,
    // for the external modules to figure out
    // handling larger blocks of incoming data
    output [NUM_BANKS*WORD_WIDTH-1:0] inst64
);

    localparam  BANK_WIDTH = (2**(ADDRESS_WIDTH));
    wire [ADDRESS_WIDTH-1:0] actual_address = addr_data[ADDRESS_WIDTH-1:0];
    //currently removed
    // but future reads can cut word width in half and
    // use twice the number of banks (+ extra check for 8/16 bit)
    // to re-implement 8 bit ports

    // [15 14 13 .. 1 0 ]
    wire [ADDRESS_WIDTH-3:0] addr_high = actual_address[ADDRESS_WIDTH-1:2];
    wire [1:0] addr_low = actual_address[1:0];
    wire [ADDRESS_WIDTH-3:0] inst_high = inst_addr[ADDRESS_WIDTH-1:2];
    // low 2 bits of inst_addr ignored

    reg [WORD_WIDTH-1:0] bank_rd_data [0:NUM_BANKS-1];
    reg [WORD_WIDTH-1:0] bank_rd [0:NUM_BANKS-1];

    integer j;
    initial begin
        for(j=0;j<NUM_BANKS;j = j + 1) begin
            bank_rd_data[j] = 0;
            bank_rd[j] = 0;
        end
    end

    genvar i;
    generate
        for(i=0;i<NUM_BANKS;i=i+1) begin : gen_banks
            (* ram_style = "block" *) reg [WORD_WIDTH-1:0] ram [0:BANK_WIDTH-1];

            initial begin
                for (j=0;j<BANK_WIDTH; j=j+1) begin
                    ram[j]=0;
                end
            end

            always @(posedge clk) begin

                if (!stall && addr_low == i) begin
                    if (write_enable) ram[addr_high] <= data_in;
                    else if (read_enable) bank_rd_data[i] <= ram[addr_high];
                end
                if(!stall) begin
                    bank_rd[i] <= ram[inst_high];
                end
            end
        end
    endgenerate

    //crap to make synthesis happy
     // Original combinational output (now internal)
    wire [WORD_WIDTH-1:0] data_out_comb;
    assign data_out_comb = (read_enable) ? bank_rd_data[addr_low] : {WORD_WIDTH{1'bz}};

    // New registered output for data
    reg [WORD_WIDTH-1:0] data_out_reg;
    always @(posedge clk) begin
        if (!stall) begin
            data_out_reg <= data_out_comb;
        end
    end
    assign data_out = data_out_reg;

    // Original combinational instruction output (internal)
    wire [NUM_BANKS*WORD_WIDTH-1:0] inst64_comb;
    generate
        for (i = 0; i < NUM_BANKS; i = i + 1) begin : concat
            assign inst64_comb[(i+1)*WORD_WIDTH-1 : i*WORD_WIDTH] = bank_rd[NUM_BANKS-i-1];
        end
    endgenerate

    // New registered output for instructions
    reg [NUM_BANKS*WORD_WIDTH-1:0] inst64_reg;
    always @(posedge clk) begin
        if (!stall) begin
            inst64_reg <= inst64_comb;
        end
    end
    assign inst64 = inst64_reg;


    initial begin
        data_out_reg = 0;
        inst64_reg = 0;
    end
endmodule
