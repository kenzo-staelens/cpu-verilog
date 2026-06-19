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

    //completely broken for stuff halfway between two banks
    // fix for inst size 4, and 1 byte registers
    //and fix parameters later

//    reg [7:0] ram [0:2**ADDRESS_WIDTH-1];
    reg [7:0] bank_rd_data [0:1];
    // reg [7:0] bank_rdata [0:7];
    // reg [63:0] bank_inst_64;
    // on stall output default 0; kind of just fixes another init issue i handles
    // just make sure cycle 1 starts with reset = high

    // large mux to determine init values
    // important note: this *NEEDS* the simulation guard so that all future instructions 
    // can read correctly and don't get mangled starting at the first due to bad init
    reg [2:0] mux_addr;
    assign inst64 = (mux_addr == 0)? {gen_banks[0].bank_rdata, gen_banks[1].bank_rdata, gen_banks[2].bank_rdata, gen_banks[3].bank_rdata, gen_banks[4].bank_rdata, gen_banks[5].bank_rdata, gen_banks[6].bank_rdata, gen_banks[7].bank_rdata} :
                    (mux_addr == 1)? {gen_banks[1].bank_rdata, gen_banks[2].bank_rdata, gen_banks[3].bank_rdata, gen_banks[4].bank_rdata, gen_banks[5].bank_rdata, gen_banks[6].bank_rdata, gen_banks[7].bank_rdata, gen_banks[0].bank_rdata} :
                    (mux_addr == 2)? {gen_banks[2].bank_rdata, gen_banks[3].bank_rdata, gen_banks[4].bank_rdata, gen_banks[5].bank_rdata, gen_banks[6].bank_rdata, gen_banks[7].bank_rdata, gen_banks[0].bank_rdata, gen_banks[1].bank_rdata} :
                    (mux_addr == 3)? {gen_banks[3].bank_rdata, gen_banks[4].bank_rdata, gen_banks[5].bank_rdata, gen_banks[6].bank_rdata, gen_banks[7].bank_rdata, gen_banks[0].bank_rdata, gen_banks[1].bank_rdata, gen_banks[2].bank_rdata} :
                    (mux_addr == 4)? {gen_banks[4].bank_rdata, gen_banks[5].bank_rdata, gen_banks[6].bank_rdata, gen_banks[7].bank_rdata, gen_banks[0].bank_rdata, gen_banks[1].bank_rdata, gen_banks[2].bank_rdata, gen_banks[3].bank_rdata} :
                    (mux_addr == 5)? {gen_banks[5].bank_rdata, gen_banks[6].bank_rdata, gen_banks[7].bank_rdata, gen_banks[0].bank_rdata, gen_banks[1].bank_rdata, gen_banks[2].bank_rdata, gen_banks[3].bank_rdata, gen_banks[4].bank_rdata} :
                    (mux_addr == 6)? {gen_banks[6].bank_rdata, gen_banks[7].bank_rdata, gen_banks[0].bank_rdata, gen_banks[1].bank_rdata, gen_banks[2].bank_rdata, gen_banks[3].bank_rdata, gen_banks[4].bank_rdata, gen_banks[5].bank_rdata} :
                    (mux_addr == 7)? {gen_banks[7].bank_rdata, gen_banks[0].bank_rdata, gen_banks[1].bank_rdata, gen_banks[2].bank_rdata, gen_banks[3].bank_rdata, gen_banks[4].bank_rdata, gen_banks[5].bank_rdata, gen_banks[6].bank_rdata} :
                    0;
    assign data_out = {bank_rd_data[0], bank_rd_data[1]};

    initial begin
        mux_addr = 0;
    end

    always @(posedge clk) begin
        mux_addr <= inst_addr[2:0];
    end

    genvar i;
    integer a;
    generate
        for (i=0; i<8; i=i+1) begin : gen_banks
            reg [7:0] ram [0:2**(ADDRESS_WIDTH-3)-1];
            reg [7:0] bank_rdata;
            
            wire [WORD_WIDTH-1:0] addr_plus = addr_data+1;
            wire [0:0] offset = (addr_plus[2:0] == i);
            wire [WORD_WIDTH-1:0] addr_offset = addr_data + offset;
            wire [WORD_WIDTH-1:0] inst_i = inst_addr+(7-i);


            // ram is indexed [0:64k] for future programming logic
            // but man is the math a fucking nightmare to figure
            // out correct indexing

            initial begin
                for (a=0;a<2**(ADDRESS_WIDTH-3)-1; a=a+1) begin
                    ram[a] = 0;
                end
                if (i == 0) $readmemh("/home/kenzo/Desktop/cpu-verilog/reg_data/ram_0.mem", ram);
                if (i == 1) $readmemh("/home/kenzo/Desktop/cpu-verilog/reg_data/ram_1.mem", ram);
                if (i == 2) $readmemh("/home/kenzo/Desktop/cpu-verilog/reg_data/ram_2.mem", ram);
                if (i == 3) $readmemh("/home/kenzo/Desktop/cpu-verilog/reg_data/ram_3.mem", ram);
                if (i == 4) $readmemh("/home/kenzo/Desktop/cpu-verilog/reg_data/ram_4.mem", ram);
                if (i == 5) $readmemh("/home/kenzo/Desktop/cpu-verilog/reg_data/ram_5.mem", ram);
                if (i == 6) $readmemh("/home/kenzo/Desktop/cpu-verilog/reg_data/ram_6.mem", ram);
                if (i == 7) $readmemh("/home/kenzo/Desktop/cpu-verilog/reg_data/ram_7.mem", ram);
                bank_rdata = ram[0];
                // bank_rdata[i] = ram[0];
            end
            always @(posedge clk) begin
                if (!stall) begin
                    if (addr_data[2:0] == i || addr_plus[2:0] == i) begin
                        if (write_enable) begin
                            // note: "reversed" bit order in ram for indexing
                            ram[addr_offset[ADDRESS_WIDTH-1:3]] <= offset ? data_in[7:0] : data_in[15:8];
                        end else if (read_enable) begin
                            // still kinda fucked needs same treatment as bank_rdata but... less wide
                            if(i<2)bank_rd_data[i] <= ram[addr_offset[ADDRESS_WIDTH-1:3]];
                        end
                    end
                    bank_rdata <= ram[inst_i[ADDRESS_WIDTH-1:3]];
                    // bank_rdata[i] <= ram[inst_i[ADDRESS_WIDTH-1:3]];
                end
            end
        end
    endgenerate

endmodule
