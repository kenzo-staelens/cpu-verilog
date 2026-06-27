module uart_rx # (
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD_RATE = 115200
)(
    input clk,          // FPGA clock
    input rx_in,        // Serial input
    output [7:0] data,  // Received data
    output data_valid   // Data ready to read
);

localparam BIT_TIME = CLK_FREQ / BAUD_RATE;
localparam HALF_BIT = BIT_TIME / 2;
reg [3:0] state = 0;
reg [15:0] counter = 0;
reg [7:0] shift_reg = 0;
always @(posedge clk) begin
    case (state)
        0: begin  // Wait for start bit (falling edge)
            if (!rx_in) begin
                counter <= 0;
                state <= 1;
            end
        end
        1: begin  // Sample mid-start bit
            if (counter == HALF_BIT - 1) begin
                if (!rx_in) begin  // Confirm start bit
                    counter <= 0;
                    state <= 2;
                end else state <= 0;  // False start
            end else counter <= counter + 1;
        end
        2,3,4,5,6,7,8,9: begin  // Sample data bits
            if (counter == BIT_TIME - 1) begin
                shift_reg[state - 2] <= rx_in;  // Store bit
                counter <= 0;
                state <= state + 1;
            end else counter <= counter + 1;
        end
        10: begin  // Stop bit
            if (counter == BIT_TIME - 1) begin
                counter <= 0;
                state <= 0;
            end else counter <= counter + 1;
        end
    endcase
end
assign data = shift_reg;
assign data_valid = (state == 10 && counter == BIT_TIME - 1);
endmodule