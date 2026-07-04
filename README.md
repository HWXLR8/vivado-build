# PYNQ-Z2 RTL Build Flow

This project builds and flashes a simple RTL design for the PYNQ-Z2 using Vivado from the command line inside Docker.

## Hardware

```text
Board:    PYNQ-Z2
Device:   Zynq-7000 XC7Z020CLG400-1
Flow:     Vivado 2023.2 CLI inside Docker
Host:     Gentoo Linux
```

## Main idea

The PYNQ-Z2 does not provide a simple free-running PL clock directly to user RTL.

This project uses the Zynq Processing System to generate `FCLK_CLK0`, then uses that clock for the FPGA logic.

```text
Zynq PS
└── FCLK_CLK0
    └── fpga_top.v
        └── blinky.v
```

## Project layout

```text
.
├── Dockerfile                   # Docker image used to run Vivado
├── Makefile                     # Main command interface
├── install.sh                   # Installs Vivado or Vitis Embedded into ~/xilinx-install
├── vivado_install_config.txt    # Batch install config for Vivado
├── vitis_install_config.txt     # Batch install config for Vitis Embedded / xsct
└── proj/
    ├── src/
    │   ├── blinky.v             # User RTL logic
    │   └── fpga_top.v           # Real FPGA top-level wrapper
    ├── xdc/
    │   └── pynq_z2.xdc          # PYNQ-Z2 pin constraints
    └── tcl/
        ├── setup_project.tcl    # Creates the Vivado project and PS7 block design
        └── build_bitstream.tcl  # Builds the bitstream from the existing project
```

Generated files are not committed:

```text
proj/pynq_z2_rtl/     # Generated Vivado project
proj/pynq_z2_rtl.bit  # Generated bitstream
```

## Make targets

```text
make setup
└── Create the Vivado project and PS7 block design.
    Run this once after a clean checkout or after deleting the generated project.

make build
└── Build the bitstream if RTL, XDC, or build Tcl inputs changed.

make flash
└── Flash proj/pynq_z2_rtl.bit to the PYNQ-Z2 using openFPGALoader.

make cold
└── Flash the bitstream, then initialize the Zynq PS.
    Use this after a full board power cycle.

make init
└── Initialize the Zynq PS over JTAG using xsct.
    Runs ps7_init and ps7_post_config.

make rebuild
└── Delete the generated Vivado project and recreate it from scratch.

make clean
└── Remove generated Vivado output.

make verify
└── Confirm Vivado runs inside the Docker container.

make shell
└── Open an interactive shell inside the Vivado Docker container.

make detect
└── Detect connected JTAG boards using openFPGALoader.

make image
└── Build the Vivado Docker image.
```

## Normal workflow

For a clean checkout:

```text
make setup
```

For normal RTL development:

```text
edit proj/src/blinky.v
make build
make flash
```

## Cold boot workflow

After fully power-cycling the board:

```text
make cold
```

After `make cold` has run once, repeated warm flashes usually only need:

```text
make build
make flash
```

## When to use each command

```text
Change logic inside an existing RTL file
└── make build
    make flash

Add, remove, or rename Verilog files
└── make setup
    make build
    make flash

Change pin constraints
└── make build
    make flash

Change PS/block-design settings
└── make rebuild
    make cold

Power cycle the board
└── make cold

Generated project gets confused
└── make rebuild
```

## Why make init is needed

The user RTL is clocked by `FCLK_CLK0` from the Zynq Processing System.

After a cold power-up, the PL bitstream can be loaded, but the PS-generated clock may not be running yet.

```text
Cold power-up
├── PL bitstream loaded: yes
├── PS FCLK_CLK0 running: no
└── User RTL clocked: no
```

`make init` connects to the Zynq PS over JTAG and runs Vivado's generated `ps7_init.tcl`.

```text
make init
└── xsct
    └── connect to Zynq PS over JTAG
        └── run ps7_init
            └── enable/configure PS clocking, including FCLK_CLK0
```

After that:

```text
Initialized board
├── PL bitstream loaded: yes
├── PS FCLK_CLK0 running: yes
└── User RTL clocked: yes
```
