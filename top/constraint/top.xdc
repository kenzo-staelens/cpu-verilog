set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]


set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 50.000 -name sys_clk_pin -add [get_ports clk]

## LEDs
set_false_path -to [get_ports {peek_out[*]}]
set_property PACKAGE_PIN U16 [get_ports {peek_out[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {peek_out[0]}]

set_property PACKAGE_PIN E19 [get_ports {peek_out[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {peek_out[1]}]

set_property PACKAGE_PIN U19 [get_ports {peek_out[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {peek_out[2]}]

set_property PACKAGE_PIN V19 [get_ports {peek_out[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {peek_out[3]}]

set_property PACKAGE_PIN W18 [get_ports {peek_out[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {peek_out[4]}]

set_property PACKAGE_PIN U15 [get_ports {peek_out[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {peek_out[5]}]

set_property PACKAGE_PIN U14 [get_ports {peek_out[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {peek_out[6]}]

set_property PACKAGE_PIN V14 [get_ports {peek_out[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {peek_out[7]}]

set_property PACKAGE_PIN V13 [get_ports {peek_out[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {peek_out[8]}]

set_property PACKAGE_PIN V3 [get_ports {peek_out[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {peek_out[9]}]

set_property PACKAGE_PIN W3 [get_ports {peek_out[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {peek_out[10]}]

set_property PACKAGE_PIN U3 [get_ports {peek_out[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {peek_out[11]}]

set_property PACKAGE_PIN P3 [get_ports {peek_out[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {peek_out[12]}]

set_property PACKAGE_PIN N3 [get_ports {peek_out[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {peek_out[13]}]

set_property PACKAGE_PIN P1 [get_ports {peek_out[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {peek_out[14]}]

set_property PACKAGE_PIN L1 [get_ports {peek_out[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {peek_out[15]}]

# Switches

## Switches
set_property PACKAGE_PIN V17 [get_ports {peek_address[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {peek_address[0]}]

set_property PACKAGE_PIN V16 [get_ports {peek_address[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {peek_address[1]}]

set_property PACKAGE_PIN W16 [get_ports {peek_address[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {peek_address[2]}]

set_property PACKAGE_PIN W17 [get_ports {peek_address[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {peek_address[3]}]

# UNUSED register bits
# set_property PACKAGE_PIN W15 [get_ports {peek_address[4]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {peek_address[4]}]

# set_property PACKAGE_PIN V15 [get_ports {peek_address[5]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {peek_address[5]}]

# set_property PACKAGE_PIN W14 [get_ports {peek_address[6]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {peek_address[6]}]

# set_property PACKAGE_PIN w13 [get_ports {peek_address[7]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {peek_address[7]}]

# set_property PACKAGE_PIN V2 [get_ports {peek_address[8]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {peek_address[8]}]

# set_property PACKAGE_PIN T3 [get_ports {peek_address[9]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {peek_address[9]}]

# set_property PACKAGE_PIN T2 [get_ports {peek_address[10]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {peek_address[10]}]

# set_property PACKAGE_PIN R3 [get_ports {peek_address[11]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {peek_address[11]}]

# set_property PACKAGE_PIN W2 [get_ports {peek_address[12]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {peek_address[12]}]

# set_property PACKAGE_PIN U1 [get_ports {peek_address[13]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {peek_address[13]}]

# set_property PACKAGE_PIN T1 [get_ports {peek_address[14]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {peek_address[14]}]

# set_property PACKAGE_PIN R2 [get_ports {peek_address[15]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {peek_address[15]}]


# UNCONNECTED/UNUSED (IO Control)
# set_property IO_BUFFER_TYPE none [get_ports opcode]
# set_property IO_BUFFER_TYPE none [get_ports ctrl_en_io]
# set_property IO_BUFFER_TYPE none [get_ports incoming_io]
# set_property IO_BUFFER_TYPE none [get_ports outgoing_io]
