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

    //input [WORD_WIDTH-1:0] inst_addr_l,
    input [15:0] inst_addr,
    // for the external modules to figure out
    // handling larger blocks of incoming data
    output [63:0] inst64
);

    // somehow complains inst_addr_l [15] and addr_data[15] unused?
    //should convert to a mux if possible
    // double width for case of weird read between 2 address lines
    // and we do not want to duplicate the entire block of bram to allow 2 read ports + x
    // with a little bit of extra indexing wires this may even support 8bit cells but not preferred
    // due to bram block sizes being naturally 18 or 36 bits (which 16 fits nicely
    // assign inst64 = inst_bank[128-16-(inst_addr_l[2:0]+1)*16-1 -:64];
    wire [127:0] inst_wire = {
        gen_banks[0].inst_reg,
        gen_banks[1].inst_reg,
        gen_banks[2].inst_reg,
        gen_banks[3].inst_reg,
        gen_banks[4].inst_reg,
        gen_banks[5].inst_reg,
        gen_banks[6].inst_reg,
        gen_banks[7].inst_reg
    };
    reg [63:0] inst64_reg;
    assign inst64 = (stall) ? inst_wire[127:+64] : inst_wire[(7-inst_addr[2:0]+1)*16-1 -:64];
    always @(posedge clk) begin
        inst64_reg <= (stall) ? inst_wire[127:+64] : inst_wire[(7-inst_addr[2:0]+1)*16-1 -:64];
    end

    assign data_out = (!read_enable) ? 0 :
                      (addr_data[2:0] == 0) ? gen_banks[0].data_bank :
                      (addr_data[2:0] == 1) ? gen_banks[1].data_bank :
                      (addr_data[2:0] == 2) ? gen_banks[2].data_bank :
                      (addr_data[2:0] == 3) ? gen_banks[3].data_bank :
                      (addr_data[2:0] == 4) ? gen_banks[4].data_bank :
                      (addr_data[2:0] == 5) ? gen_banks[5].data_bank :
                      (addr_data[2:0] == 6) ? gen_banks[6].data_bank :
                      (addr_data[2:0] == 7) ? gen_banks[7].data_bank :
                      0;


    genvar i;
    integer a;
    generate
    	for(i=0;i<8;i=i+1) begin : gen_banks
    		reg [15:0] ram [0:8191];
    		reg [15:0] data_bank;
    		reg [15:0] inst_reg;
    
    		wire [16:0] inst_i = inst_addr + (7-i);
    
            initial begin
                for (a=0;a<8192; a=a+1) begin
                    ram[a] = 0;
                end
                // TODO fix this crap
                if (i == 0) $readmemh("/home/kenzo/Desktop/cpu-verilog/reg_data/ram_0.mem", ram);
                if (i == 1) $readmemh("/home/kenzo/Desktop/cpu-verilog/reg_data/ram_1.mem", ram);
                if (i == 2) $readmemh("/home/kenzo/Desktop/cpu-verilog/reg_data/ram_2.mem", ram);
                if (i == 3) $readmemh("/home/kenzo/Desktop/cpu-verilog/reg_data/ram_3.mem", ram);
                if (i == 4) $readmemh("/home/kenzo/Desktop/cpu-verilog/reg_data/ram_4.mem", ram);
                if (i == 5) $readmemh("/home/kenzo/Desktop/cpu-verilog/reg_data/ram_5.mem", ram);
                if (i == 6) $readmemh("/home/kenzo/Desktop/cpu-verilog/reg_data/ram_6.mem", ram);
                if (i == 7) $readmemh("/home/kenzo/Desktop/cpu-verilog/reg_data/ram_7.mem", ram);
                // inst_bank[(7-i+1)*16-1:(7-i)*16] = ram[0];
                // inst_bank[(7-i+1)*16-1:(7-i)*16] = ram[0];
                inst_reg = ram[0];
            end

    		always @(posedge clk) begin
                if (!stall) begin
        		    if (write_enable) begin
        	    		if (addr_data[2:0] == i) begin
        	    			ram[addr_data[15:3]] <= data_in;
        	    		end
        		    end else begin
        	    		data_bank <= ram[addr_data[15:3]];
        		    end
                end
    		    // inst_bank[(7-i+1)*16-1:(7-i)*16] <= ram[inst_i[15:3]];
    		    inst_reg <= ram[inst_i[15:3]];
    		end
    	end
    endgenerate
endmodule
