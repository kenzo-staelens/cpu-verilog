module UART #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD_RATE = 115200
) (
    input clk,
    input [7:0] data_send,
    input cs, // chip select

    output [7:0] data_rcv,

    // rx/tx
    input serial_in,
    output serial_out,

    // status out
    output data_waiting,
    output clear_to_send,

    // "status" in
    input event_read,
    input event_write
);

// dirty internal 1 entry fifo; drop when too many
wire data_valid;
reg unhandled_wait;
reg [7:0] sending_data;
reg send_waiting;

assign data_waiting = unhandled_wait;

initial begin
    unhandled_wait = 0;
    sending_data = 0;
    send_waiting = 0;
end

// currently not using a fifo buffer
// if data gets overwritten -> too bad

always @(posedge clk) begin
    // internal device handlers
    if (data_valid && !unhandled_wait) unhandled_wait <= 1;
    if (send_waiting && !clear_to_send) begin
        send_waiting <= 0;
    end
    // active events from cpu
    if (cs) begin
        if (event_read) unhandled_wait <= 0;
    
        if (event_write) begin
            sending_data <= data_send;
            send_waiting <= 1;
        end
    end
end

uart_tx #(
    .BAUD_RATE(BAUD_RATE),
    .CLK_FREQ(CLK_FREQ)
) tx (
    .clk(clk),
    .data(sending_data),
    .tx_start(send_waiting),  // status from cpu
    .tx_out(serial_out),
    .tx_done(clear_to_send)  // status to cpu
);

uart_rx #(
    .BAUD_RATE(BAUD_RATE),
    .CLK_FREQ(CLK_FREQ)
) rx (
    .clk(clk),
    .rx_in(serial_in),
    .data(data_rcv),
    .data_valid(data_valid) // note: set to 0 on next clock
);


endmodule