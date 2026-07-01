create_project hello_proj ./hello_proj -part xc7z020clg400-1 -force
add_files top.v
add_files -fileset constrs_1 top.xdc
set_property top top [current_fileset]
synth_design -top top -part xc7z020clg400-1
opt_design
place_design
report_io
report_clocks
route_design
report_utilization
write_bitstream -force hello.bit
