create_project hello_proj ./hello_proj -part xc7z020clg400-1 -force
set_property board_part tul.com.tw:pynq-z2:part0:1.0 [current_project]

add_files top.v

create_bd_design "system"
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
apply_bd_automation \
  -rule xilinx.com:bd_rule:processing_system7 \
  -config { make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" } \
  [get_bd_cells processing_system7_0]
set_property CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {125} [get_bd_cells processing_system7_0]
set_property CONFIG.PCW_USE_M_AXI_GP0 {0} [get_bd_cells processing_system7_0]

create_bd_cell -type module -reference top top_0
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] \
               [get_bd_pins top_0/clk]
make_bd_pins_external [get_bd_pins top_0/btn]
make_bd_pins_external [get_bd_pins top_0/led]

validate_bd_design
save_bd_design
generate_target all [get_files system.bd]

make_wrapper -files [get_files system.bd] -top
add_files -norecurse ./hello_proj/hello_proj.srcs/sources_1/bd/system/hdl/system_wrapper.v
set_property top system_wrapper [current_fileset]
update_compile_order -fileset sources_1

add_files -fileset constrs_1 top.xdc

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

file copy -force ./hello_proj/hello_proj.runs/impl_1/system_wrapper.bit hello.bit
