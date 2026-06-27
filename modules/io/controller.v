module IOController (
    input clk,
    input enable,
    input [3:0] opcode,
    input [15:0] io_arg,

    output [7:0] incoming_io, // to cpu
    output read_event,
    output write_event,

    //wires to individual devices
    //expand pins as needed
    input [7:0] device_status_in_1,
    input [7:0] device_data_in_1,
    output select_1
);

reg [7:0] active_device;

initial begin
    active_device = 0;
end

always @(posedge clk) begin
    if (enable && opcode == 5) active_device <= io_arg[7:0]; 
end

wire [7:0] device_data;
wire [7:0] device_status;

assign read_event = (enable && opcode == 2);
assign write_event = (enable && opcode == 3);
assign device_status = (opcode == 4) ? 
                        (active_device == 0) ? device_status_in_1 : 0
                        : 0; 
assign device_data = (opcode == 2) ? 
                        (active_device == 0) ? device_data_in_1 : 0
                        : 0; 

assign incoming_io = (enable) ? // to cpu
                     (opcode == 2) ? device_data :
                     (opcode == 4) ? device_status : 0
                     : 0;
assign select_1 = (enable && active_device == 0);
endmodule