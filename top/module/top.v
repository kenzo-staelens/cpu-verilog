module Top#(
    REGISTER_BITS = 4,
    WORD_WIDTH = 16
) (
    input real_clk,
    input [5:0] peek_address,
    output [WORD_WIDTH-1:0] peek_out,

    input uart_serial_in,
    output uart_serial_out 
);
    // bootloader, stabilizing signals etc
    wire rst;
    wire [15:0] uart_debug_rx;
    wire [15:0] uart_debug_tx;
    wire [15:0] cpu_peek;
    assign peek_out = cpu_peek;
    // assign peek_out = peek_address[5:4] == 0 ? cpu_peek :
    //                   peek_address[5:4] == 1 ? uart_debug_rx :
    //                   peek_address[5:4] == 2 ? uart_debug_tx :
    //                   255;
    
    reg [1:0] clk_reg;
    initial begin
        clk_reg = 0;
    end
    always @(posedge real_clk) begin
        clk_reg = clk_reg + 1;
    end
    assign clk = clk_reg[1];
    
    BootModule boot(.clk(clk), .rst_wire(rst));

    wire [3:0] opcode;
    wire [WORD_WIDTH-1:0] incoming_io;
    wire [WORD_WIDTH-1:0] outgoing_io;
    wire [7:0] incoming_io_trunk;
    wire [7:0] outgoing_io_trunk = outgoing_io[7:0];
       assign incoming_io = {{(WORD_WIDTH-8){1'b0}}, incoming_io_trunk};

    
    // actual cpu
    CPU #(
        .INST_SIZE(2),
        .WORD_WIDTH(WORD_WIDTH),
        .REGISTER_BITS(REGISTER_BITS),
        .RAM_ADDR_WIDTH(16),
        .PERSIST_ADDR_WIDTH(15)
    ) cpu (
        .rst(rst),
        .clk(clk),
        // additionally used as ready signal from external sources
        // this module runs when reset is low
        .peek_address(peek_address[3:0]), // REGISTER_BITS
        .peek_out(cpu_peek),

        // export io
        // reserved signals
        // note IO is, in addition to IO signals
        // kind of a trash can for other uncategorized signals
        // 0 = NOP
        // 1 = counter
        .opcode(opcode),
        .ctrl_en_io(ctrl_en_io),
        .incoming_io(incoming_io),
        .outgoing_io(outgoing_io)
    );

    // IO crap
    IOController iocontroller (
        .clk(clk),
        .opcode(opcode),
        .enable(ctrl_en_io),
        .io_arg(outgoing_io),
        .incoming_io(incoming_io_trunk),
        .read_event(read_event),
        .write_event(write_event),
        .device_status_in_1(uart_status),
        .device_data_in_1(uart_data_rcv),
        .select_1(cs_uart)
    );

    wire [7:0] uart_status;
    wire [7:0] uart_data_rcv;
    // hooked up to device ID 0
    UART #(
        .CLK_FREQ(100_000_000), //hardcoded this is FPGA clock speed
        // .BAUD_RATE(9600)
        .BAUD_RATE(115200)
    ) uart_io (
        .clk(real_clk),
        .data_send(outgoing_io_trunk),
        .cs(cs_uart),
        .data_rcv(uart_data_rcv),
        .serial_in(uart_serial_in),  //constraint
        .serial_out(uart_serial_out),  //constraint
        .data_waiting(uart_status[1]),
        .clear_to_send(uart_status[0]),
        .event_read(read_event),
        .event_write(write_event),
        .uart_debug_rx(uart_debug_rx),
        .uart_debug_tx(uart_debug_tx)
    );
endmodule

module BootModule #(
    parameter PULSES=3
) (
    input clk,
    output rst_wire
);

    reg [$clog2(PULSES)-1:0] reset_pulse;
    reg rst;
    assign rst_wire = rst;

    initial begin
        reset_pulse = 0;
        rst = 1;
    end

    always @(posedge clk) begin
        if (reset_pulse<PULSES) reset_pulse <= reset_pulse+1;
        else rst<=0;
    end
endmodule

