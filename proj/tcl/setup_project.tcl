create_project pynq_z2_rtl ./pynq_z2_rtl -part xc7z020clg400-1 -force
set_property board_part tul.com.tw:pynq-z2:part0:1.0 [current_project]

add_files [glob ./src/*.v]
add_files ./third_party/light8080/verilog/rtl/light8080.v
add_files ./third_party/light8080/verilog/rtl/micro_rom.v

create_bd_design "system"
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
apply_bd_automation \
  -rule xilinx.com:bd_rule:processing_system7 \
  -config { make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" } \
  [get_bd_cells processing_system7_0]

set_property CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {125} [get_bd_cells processing_system7_0]
set_property CONFIG.PCW_USE_M_AXI_GP0 {0} [get_bd_cells processing_system7_0]

make_bd_pins_external [get_bd_pins processing_system7_0/FCLK_CLK0]

validate_bd_design
save_bd_design
generate_target all [get_files system.bd]

make_wrapper -files [get_files system.bd] -top
add_files -norecurse ./pynq_z2_rtl/pynq_z2_rtl.srcs/sources_1/bd/system/hdl/system_wrapper.v

set_property top fpga_top [current_fileset]
update_compile_order -fileset sources_1

add_files -fileset constrs_1 ./xdc/pynq_z2.xdc

launch_runs impl_1 -to_step write_bitstream -jobs 32
wait_on_run impl_1

file copy -force ./pynq_z2_rtl/pynq_z2_rtl.runs/impl_1/fpga_top.bit pynq_z2_rtl.bit
