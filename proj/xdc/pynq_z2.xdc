set_property -dict { PACKAGE_PIN D20 IOSTANDARD LVCMOS33 } [get_ports btn]
set_property -dict { PACKAGE_PIN M14 IOSTANDARD LVCMOS33 } [get_ports led]
# set_property -dict { PACKAGE_PIN Y18 IOSTANDARD LVCMOS33 } [get_ports uart_tx]

## PMODA (J1)
set_property -dict {PACKAGE_PIN Y18 IOSTANDARD LVCMOS33} [get_ports {vga_r[0]}]
set_property -dict {PACKAGE_PIN Y19 IOSTANDARD LVCMOS33} [get_ports {vga_r[1]}]
set_property -dict {PACKAGE_PIN Y16 IOSTANDARD LVCMOS33} [get_ports {vga_r[2]}]
set_property -dict {PACKAGE_PIN Y17 IOSTANDARD LVCMOS33} [get_ports {vga_r[3]}]

set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports {vga_b[0]}]
set_property -dict {PACKAGE_PIN U19 IOSTANDARD LVCMOS33} [get_ports {vga_b[1]}]
set_property -dict {PACKAGE_PIN W18 IOSTANDARD LVCMOS33} [get_ports {vga_b[2]}]
set_property -dict {PACKAGE_PIN W19 IOSTANDARD LVCMOS33} [get_ports {vga_b[3]}]


## PMODB (J2)
set_property -dict {PACKAGE_PIN W14 IOSTANDARD LVCMOS33} [get_ports {vga_g[0]}]
set_property -dict {PACKAGE_PIN Y14 IOSTANDARD LVCMOS33} [get_ports {vga_g[1]}]
set_property -dict {PACKAGE_PIN T11 IOSTANDARD LVCMOS33} [get_ports {vga_g[2]}]
set_property -dict {PACKAGE_PIN T10 IOSTANDARD LVCMOS33} [get_ports {vga_g[3]}]

set_property -dict {PACKAGE_PIN V16 IOSTANDARD LVCMOS33} [get_ports {vga_hsync}]
set_property -dict {PACKAGE_PIN W16 IOSTANDARD LVCMOS33} [get_ports {vga_vsync}]
