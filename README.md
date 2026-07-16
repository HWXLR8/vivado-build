# Containerized Vivado/Vitis Workflow for Linux

This repository provides a Docker-based command-line workflow for installing
and running Vivado and Vitis Embedded on Linux. The Makefile covers project
generation, linting, bitstream builds, JTAG programming, and Zynq PS
initialization for the PYNQ-Z2.

The included RTL is an early, work-in-progress Space Invaders FPGA core. It
currently integrates a Light8080 CPU, a basic memory map, framebuffer, and VGA
output; it is an example design rather than the primary purpose of the
repository.

## Project layout

```text
.
├── Dockerfile                   # Vivado container image
├── Makefile                     # Build, programming, and setup commands
├── install.sh                   # Installs Vivado or Vitis Embedded
└── proj/
    ├── src/
    │   ├── fpga_top.v           # Example design top level
    │   ├── light8080_adapter.v  # Example CPU bus adapter
    │   ├── memmap.v             # Example address decoding
    │   ├── vram.v               # Example framebuffer
    │   └── vga.v                # Example VGA output
    ├── third_party/light8080/    # Example CPU core submodule
    ├── tcl/                      # Vivado project and bitstream scripts
    └── xdc/                      # PYNQ-Z2 pin constraints
```

Generated Vivado files and `proj/pynq_z2_rtl.bit` are not committed.

## Getting started

Initialize the example design's CPU submodule after cloning:

```sh
git submodule update --init --recursive
```

The workflow uses Vivado/Vitis 2023.2 under `xilinx-install/`. Place the Xilinx
unified installer archive expected by `install.sh` in the repository root, then
run `make install-vivado` (and `make install-vitis` when PS initialization is
needed). Use `make verify` to check the Vivado installation.

Create the generated Vivado project, build it, and program the board:

```sh
make setup
make build
make flash
```

After a full power cycle, use `make cold` instead of `make flash`. It programs
the bitstream and initializes the Zynq PS so that `FCLK_CLK0` is running. This
requires Vitis Embedded, which can be installed with `make install-vitis`.

## Useful targets

| Target | Purpose |
| --- | --- |
| `make lint` | Check the standalone Verilog sources with Icarus Verilog. |
| `make setup` | Create the Vivado project and PS7 block design. |
| `make build` | Lint and build the bitstream when inputs have changed. |
| `make flash` | Program the built bitstream with openFPGALoader. |
| `make cold` | Program the board and initialize the PS after power-up. |
| `make rebuild` | Delete and recreate the generated Vivado project. |
| `make clean` | Remove generated Vivado output. |
| `make detect` | Detect JTAG devices with openFPGALoader. |
| `make help` | List all available targets. |

Run `make rebuild` after changing the set of Verilog files or the PS/block
design. Normal RTL and constraint changes only require `make build` followed by
`make flash`.
