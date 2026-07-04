`define hazard_type Hazard32
// sanity check for bit sizes of pipeline unit
`define __sanity__
// program memory and persistent storage are written as implementation specific
// due to output concatenation
module CPU #(
    parameter INST_SIZE = 2,
    parameter WORD_WIDTH = 16,
    parameter REGISTER_BITS = 4,
    parameter RAM_ADDR_WIDTH = 16,
    parameter PERSIST_ADDR_WIDTH = 16
    // TODO parameters for persistent/program memory
) (
    input clk,
    input rst,
    // additionally used as ready signal from external sources
    // this module runs when reset is low
    input [REGISTER_BITS-1:0] peek_address,
    output [WORD_WIDTH-1:0] peek_out,

    // export io
    // reserved signals
    // note IO is, in addition to IO signals
    // kind of a trash can for other uncategorized signals
    // 0 = (SS)NOP
    // 1 = counter
    output [3:0] opcode,
    output ctrl_en_io,
    input [WORD_WIDTH-1:0] incoming_io,
    output [WORD_WIDTH-1:0 ] outgoing_io
);
    localparam INSTRUCTION_BITS = INST_SIZE*16;

    wire [INSTRUCTION_BITS*2-1:0] inst64;
    wire [WORD_WIDTH-1:0] data_bus;

    wire [WORD_WIDTH-1:0] program_address;
    wire ready; // used to decide whether to discard pipeline

    wire [INSTRUCTION_BITS-1:0] inst_a;
    wire [INSTRUCTION_BITS-1:0] inst_b;
    

    Clock_wrapper #(
        .WORD_WIDTH(WORD_WIDTH),
        .INST_SIZE(INST_SIZE)
    ) clock_module (
        .clk(clk),
        .rst(rst),
        .inst64(inst64),
        .jmp(ctrl_en_jmp),
        .jmp_addr(data_bus),
        .pc_read(program_address),
        .ready(ready),
        .inst_a(inst_a),
        .inst_b(inst_b)
    );
    
    wire [REGISTER_BITS-1:0] reg_addr_a_1;
    wire [REGISTER_BITS-1:0] reg_addr_b_1;
    wire [REGISTER_BITS-1:0] reg_addr_a_2;
    wire [REGISTER_BITS-1:0] reg_addr_b_2;
    
    wire [4*REGISTER_BITS-1:0] reg_addr_bundle = {
        reg_addr_a_1,
        reg_addr_b_1,
        reg_addr_a_2,
        reg_addr_b_2
    };
    
    wire [WORD_WIDTH-1:0] reg_resp_a_1;
    wire [WORD_WIDTH-1:0] reg_resp_b_1;
    wire [WORD_WIDTH-1:0] reg_resp_a_2;
    wire [WORD_WIDTH-1:0] reg_resp_b_2;
    
    wire [4*WORD_WIDTH-1:0] reg_resp_bundle;
    
    assign {
        reg_resp_a_1,
        reg_resp_b_1,
        reg_resp_a_2,
        reg_resp_b_2
    } = reg_resp_bundle;
    
    wire [1:0] mode_1;
    wire [REGISTER_BITS-1:0] opcode_1;
    wire [REGISTER_BITS-1:0] dst_1;
    wire [WORD_WIDTH-1:0] arg_a_1;
    wire [WORD_WIDTH-1:0] arg_b_1;
    Pipeline #(
       .WORD_WIDTH(WORD_WIDTH),
       .REGISTER_BITS(REGISTER_BITS)
    ) pipeline_1 (
        //basic
        .clk(clk),
        .rst(rst),
        .ready(ready),
    
        //input fetch
        .inst(inst_a),
        
        //input decode
        .reg_addr_a(reg_addr_a_1),
        .reg_addr_b(reg_addr_b_1),
    
        //input decode
        .reg_resp_a(reg_resp_a_1),
        .reg_resp_b(reg_resp_b_1),
        
        //output exec
        .mode_exec(mode_1),
        .opcode_exec(opcode_1),
        .dst_exec(dst_1),
        .arg_a_exec(arg_a_1),
        .arg_b_exec(arg_b_1)
    );

    wire [WORD_WIDTH-1:0] alu_out_1;
    ALU #(
        .WORD_WIDTH(WORD_WIDTH)
    ) alu_1 (
        .clk(clk),
        .opcode(opcode_1),
        .arg_a(arg_a_1),
        .arg_b(arg_b_1),
        .out(alu_out_1)
    );
    
    wire [REGISTER_BITS-1:0] opcode_2;
    wire [REGISTER_BITS-1:0] dst_2;
    wire [WORD_WIDTH-1:0] arg_a_2;
    wire [WORD_WIDTH-1:0] arg_b_2;
    Pipeline #(
       .WORD_WIDTH(WORD_WIDTH)
    ) pipeline_2 (
        //basic
        .clk(clk),
        .rst(rst),
        .ready(ready),
    
        //input fetch
        .inst(inst_b),
        
        //input decode
        .reg_addr_a(reg_addr_a_2),
        .reg_addr_b(reg_addr_b_2),
    
        //input decode
        .reg_resp_a(reg_resp_a_2),
        .reg_resp_b(reg_resp_b_2),
        
        //output exec
        .mode_exec(),
        .opcode_exec(opcode_2),
        .dst_exec(dst_2),
        .arg_a_exec(arg_a_2),
        .arg_b_exec(arg_b_2)
    );

    wire [WORD_WIDTH-1:0] alu_out_2;
    ALU #(
        .WORD_WIDTH(WORD_WIDTH)
    ) alu_2 (
        .clk(clk),
        .opcode(opcode_2),
        .arg_a(arg_a_2),
        .arg_b(arg_b_2),
        .out(alu_out_2)
    );
    
    assign opcode = opcode_1;
    assign outgoing_io = arg_b_1;

    wire [WORD_WIDTH-1:0] pipeline_clock_intermediate;
    wire [WORD_WIDTH-1:0] pipelined_clock; // clock @ currently executing (alu 1)
    DelayLine #(
        .WORD_WIDTH(WORD_WIDTH)
    ) clock_delay_1 (
        .clk(clk),
        .rst(rst),
        .in(program_address),
        .out(pipeline_clock_intermediate)
    );
    DelayLine #(
        .WORD_WIDTH(WORD_WIDTH)
    ) clock_delay_2 (
        .clk(clk),
        .rst(rst),
        .in(pipeline_clock_intermediate),
        .out(pipelined_clock)
    );
    
    wire jmp_flag = (((opcode_1[2] & arg_a_1[2])|(opcode_1[1] & arg_a_1[1])|(opcode_1[0] & arg_a_1[0]))^opcode_1[3]);
    // wire jmp_flag=((opcode_1[2:0] & arg_a_1[2:0])^(&{opcode_1[3], opcode_1[3], opcode_1[3]}))!=0; // any is same or invert
    wire ctrl_en_jmp;
    // ctrl_en_io is a module output
    wire ctrl_en_store;

    // reserved signal 1
    wire [WORD_WIDTH-1:0] intermediate_incoming_io;
    assign intermediate_incoming_io = (ctrl_en_io_internal && opcode==1) ? pipelined_clock : incoming_io;

    ControlExec #(.WORD_WIDTH(WORD_WIDTH)) control_signals (
        .mode(mode_1),
        .jmp_addr(arg_b_1),
        .jmp_flag(jmp_flag),
        .data_alu(alu_out_1),
        .data_io(intermediate_incoming_io),
        .data_bus(data_bus),
        .en_jmp(ctrl_en_jmp),
        .en_io(ctrl_en_io_internal),
        .en_store(ctrl_en_store),

        // output en_store to make verilog happy
        .storage_out(storage_out)
    );

    assign ctrl_en_io = ready ? ctrl_en_io_internal : 0;

    RegFile #(
        .REGISTER_BITS(REGISTER_BITS),
        .WORD_WIDTH(WORD_WIDTH)
    ) register_file (
        .clk(clk),
        .rst(rst),

        .write_enable_1(ready),
        .write_address_1(dst_1),
        .write_data_1(data_bus),

        .write_enable_2(ready),
        .write_address_2(dst_2),
        .write_data_2(alu_out_2),

        .output_address_bus(reg_addr_bundle),
        .output_bus(reg_resp_bundle),

        .peek_address(peek_address),
        .peek_out(peek_out)
    );

    // device 0 = program memory
    // device 1 = internal persistent
    // device 2 = N/A
    // device 3 = N/A
    // correspond to select by high bits of opcode
    // bit 3 of opcode unused
    wire [1:0] str_select = opcode_1[3:2]; 

    // program memory
    // NOTE: store address = arg b (imm. or reg)
    // as it's more efficient than using a register to address ram?
    // NOTE: being read directly from pipeline unit as it's always only pipeline 1
    // if pipeline changes -> todo: clean this up
    wire ctrl_en_store_2 = pipeline_1.mode == 2'b11;
    wire progmem_re = (pipeline_1.opcode[3:2] == 2'b00) && ctrl_en_store_2 && (pipeline_1.opcode[1:0] == 2'b00);
    wire progmem_we = (pipeline_1.opcode[3:2] == 2'b00) && ctrl_en_store_2 && (pipeline_1.opcode[1:0] == 2'b01);

    ProgMemBRAM #(
        .WORD_WIDTH(WORD_WIDTH),
        .ADDRESS_WIDTH(RAM_ADDR_WIDTH),
        .NUM_BANKS(4)
    ) progmem (
        .clk(clk),
        .stall(rst),

        .write_enable(progmem_we),
        .read_enable(progmem_re),
        .addr_data(pipeline_1.data_b_int),
        // .addr_data(pipeline_1.immediate_value),
        .data_out(data_bus_progmem),
        .data_in(reg_resp_a_1),
        // .data_in(reg_resp_a_1),

        //instruction
        .inst_addr(program_address), // base of the address, goes [base: base+7]
        .inst64(inst64)
    );
    // reg_resp_a_1
    // reg_resp_b_1

    wire persistent_re = (pipeline_1.opcode == 2'b01) && ctrl_en_store_2 && (opcode_1[1:0] == 2'b00);
    wire persistent_we = (pipeline_1.opcode == 2'b01) && ctrl_en_store_2 && (opcode_1[1:0] == 2'b01);

    PersistentBRAM #(
        .WORD_WIDTH(WORD_WIDTH),
        // shouldn't really be using this much anyway
        // prefer mostly as a rom?
        .ADDRESS_WIDTH(PERSIST_ADDR_WIDTH) // can store up to one "page?" of memory
    ) persistent (
        .clk(clk),
        .stall(rst),

        .write_enable(persistent_we),
        .read_enable(persistent_re),

        .addr_data(pipeline_1.data_b_int[PERSIST_ADDR_WIDTH-1:0]),
        .data_out(data_bus_persist),
        .data_in(reg_resp_a_1)
    );

    wire [WORD_WIDTH-1:0] data_bus_persist;
    wire [WORD_WIDTH-1:0] data_bus_progmem;
    wire [WORD_WIDTH-1:0] storage_out = (progmem_re) ? data_bus_progmem :
                                        (persistent_re) ? data_bus_persist :
                                        {WORD_WIDTH{1'b0}};
endmodule
