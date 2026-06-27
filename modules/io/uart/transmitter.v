module uart_tx #(
    parameter CLK_FREQ = 50_000_000,  // 50 MHz default
    parameter BAUD_RATE = 115200      // Baud rate
) (
    input clk,          // FPGA clock (e.g., 50 MHz)
    input [7:0] data,   // 8-bit data to transmit
    input tx_start,     // Trigger transmission
    output reg tx_out,  // Serial output
    output tx_done      // Transmission complete
);

localparam BIT_TIME = CLK_FREQ / BAUD_RATE;
reg [3:0] state = 0;
reg [15:0] counter = 0;
reg [7:0] shift_reg = 0;
always @(posedge clk) begin
    case (state)
        0: begin  // Idle
            tx_out <= 1;  // High when idle
            if (tx_start) begin
                shift_reg <= data;
                state <= 1;
                counter <= 0;
            end
        end
        1: begin  // Start bit (0)
            tx_out <= 0;
            if (counter == BIT_TIME - 1) begin
                counter <= 0;
                state <= 2;
            end else counter <= counter + 1;
        end
        2,3,4,5,6,7,8,9: begin  // Data bits (LSB first)
            tx_out <= shift_reg[state - 2];
            if (counter == BIT_TIME - 1) begin
                counter <= 0;
                state <= state + 1;
            end else counter <= counter + 1;
        end
        10: begin  // Stop bit (1)
            tx_out <= 1;
            if (counter == BIT_TIME - 1) begin
                counter <= 0;
                state <= 0;
            end else counter <= counter + 1;
        end
    endcase
end
assign tx_done = (state == 0);
endmodule