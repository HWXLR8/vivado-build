set_property -dict { PACKAGE_PIN H16 IOSTANDARD LVCMOS33 } [get_ports clk]
set_property -dict { PACKAGE_PIN D19 IOSTANDARD LVCMOS33 } [get_ports rst]
set_property -dict { PACKAGE_PIN D20 IOSTANDARD LVCMOS33 } [get_ports btn]
set_property -dict { PACKAGE_PIN Y18 IOSTANDARD LVCMOS33 } [get_ports tx]
set_property -dict { PACKAGE_PIN M14 IOSTANDARD LVCMOS33 } [get_ports led]

create_clock -period 8.000 -name clk [get_ports clk]
