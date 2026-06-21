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

    reg [1:0] address_latch;


    assign data_out = (read_enable && gen_banks[0].read_latch) ? gen_banks[0].data_bank :
                      (read_enable && gen_banks[1].read_latch) ? gen_banks[1].data_bank :
                      (read_enable && gen_banks[2].read_latch) ? gen_banks[2].data_bank :
                      (read_enable && gen_banks[3].read_latch) ? gen_banks[3].data_bank : 0;

    always @(posedge clk) begin
        if (!stall) address_latch <= inst_addr;
    end

    wire [127:0] wide_wire = {gen_banks[0].inst_bank, gen_banks[1].inst_bank, gen_banks[2].inst_bank,gen_banks[3].inst_bank, gen_banks[0].inst_bank, gen_banks[1].inst_bank, gen_banks[2].inst_bank,gen_banks[3].inst_bank};
    assign inst64 = wide_wire[127-address_latch*16-:64];

    initial begin
        address_latch = 0;
    end


    genvar i;
    integer a;
    generate
        for (i=0;i<4;i=i+1) begin : gen_banks
            wire [15:0] bank_index_inst = inst_addr + (3-i);
            reg read_latch;
            wire bank_we = (write_enable && (addr_data[1:0] == i));
            wire bank_re = (read_enable && (addr_data[1:0] == i));

            reg [15:0] inst_bank;
            reg [15:0] data_bank;

            (* ram_decomp = "power", ram_style = "block" *) reg [15:0] ram [0:2**(ADDRESS_WIDTH-2)-1];

            initial begin
                for (a=0;a<2**(ADDRESS_WIDTH-2)-1; a=a+1) begin
                    ram[a] = 0;
                end
                read_latch = 0;
                data_bank = 0;
                if (i == 0) $readmemh("/home/kenzo/Desktop/cpu-verilog/reg_data/ram_0.mem", ram);
                if (i == 1) $readmemh("/home/kenzo/Desktop/cpu-verilog/reg_data/ram_1.mem", ram);
                if (i == 2) $readmemh("/home/kenzo/Desktop/cpu-verilog/reg_data/ram_2.mem", ram);
                if (i == 3) $readmemh("/home/kenzo/Desktop/cpu-verilog/reg_data/ram_3.mem", ram);
                inst_bank = ram[0];
            end

            always @(posedge clk) begin
                if (!stall) begin
                    if (bank_we) ram[addr_data[15:2]] <= data_in;
                    else if (bank_re) begin
                        data_bank <= ram[addr_data[15:2]];
                    end
                    inst_bank <= ram[bank_index_inst[15:2]];
                    read_latch <= bank_re;
                end
            end
        end
    endgenerate
endmodule
