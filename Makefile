SHELL := /bin/bash

VIVADO_VERSION  := 2023.2
IMAGE_NAME      := vivado-base:$(VIVADO_VERSION)
INSTALL_DIR     := $(CURDIR)/xilinx-install
LICENSE_DIR     := $(CURDIR)/xilinx-license
PROJ_DIR        := $(CURDIR)/proj
BOARD           := pynq_z2
BIT_FILE        := $(PROJ_DIR)/pynq_z2_rtl.bit
XPR             := $(PROJ_DIR)/pynq_z2_rtl/pynq_z2_rtl.xpr
TCL_SCRIPT      := tcl/build_bitstream.tcl
SETUP_SCRIPT    := tcl/setup_project.tcl
LINT_SOURCES    := $(filter-out $(PROJ_DIR)/src/fpga_top.v,$(wildcard $(PROJ_DIR)/src/*.v))
BUILD_INPUTS := $(wildcard $(PROJ_DIR)/src/*.v) \
                $(wildcard $(PROJ_DIR)/xdc/*.xdc) \
                $(PROJ_DIR)/third_party/light8080/verilog/rtl/light8080.v \
                $(PROJ_DIR)/third_party/light8080/verilog/rtl/micro_rom.v \
                $(PROJ_DIR)/tcl/build_bitstream.tcl \
		$(PROJ_DIR)/roms/invaders/space_invaders.hex

# Simulation (Icarus Verilog). Reuses every RTL source except fpga_top.v
# (which pulls in the un-simulatable Zynq PS7 wrapper), plus the light8080
# core files and the testbench.
SIM_DIR      := $(PROJ_DIR)/sim
ROM_HEX      := $(PROJ_DIR)/roms/invaders/space_invaders.hex
SIM_SOURCES  := $(LINT_SOURCES) \
                $(PROJ_DIR)/third_party/light8080/verilog/rtl/light8080.v \
                $(PROJ_DIR)/third_party/light8080/verilog/rtl/micro_rom.v \
                $(SIM_DIR)/tb_soc.v

# colors
GREEN := \033[1;32m
RED   := \033[1;31m
RESET := \033[0m

VIVADO_RUN = docker run --rm -it \
	-u "$$(id -u):$$(id -g)" \
	-e HOME=/tmp \
	--network host \
	-v "$(INSTALL_DIR):/opt/Xilinx" \
	-v "$(PROJ_DIR):/proj" \
	-v "$(LICENSE_DIR):/root/.Xilinx" \
	-e XILINXD_LICENSE_FILE=/root/.Xilinx \
	$(IMAGE_NAME)

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

.PHONY: install-vivado
install-vivado: ## Install Vivado
	./install.sh vivado

.PHONY: install-vitis
install-vitis: ## Install Vitis Embedded
	./install.sh vitis

.PHONY: verify
verify: ## Confirm Vivado runs and print its version
	$(VIVADO_RUN) bash -c "source /opt/Xilinx/Vivado/$(VIVADO_VERSION)/settings64.sh && vivado -version"

.PHONY: shell
shell: ## Drop into an interactive shell inside the Vivado container
	$(VIVADO_RUN) bash

.PHONY: lint
lint: ## Check Verilog syntax with iverilog
	iverilog -tnull $(LINT_SOURCES)

.PHONY: sim
sim: ## Simulate the CPU subsystem with Icarus Verilog and print a trace
	@iverilog -g2012 -o $(SIM_DIR)/soc.vvp $(SIM_SOURCES)
	@ln -sf $(ROM_HEX) $(SIM_DIR)/space_invaders.hex
	@cd $(SIM_DIR) && vvp soc.vvp

.PHONY: wave
wave: ## Open the last simulation waveform in GTKWave
	gtkwave $(SIM_DIR)/tb_soc.vcd

.PHONY: setup
setup: ## Create Vivado project and block design
	@mkdir -p "$(PROJ_DIR)"
	@printf "==> Setting up Vivado project...\n"
	@$(VIVADO_RUN) bash -c "source /opt/Xilinx/Vivado/$(VIVADO_VERSION)/settings64.sh && cd /proj && vivado -mode batch -source $(SETUP_SCRIPT)" && \
		printf "$(GREEN)SUCCESS! Vivado project setup complete$(RESET)\n" || \
		{ rc=$$?; printf "$(RED)FAIL! Vivado project setup failed$(RESET)\n"; exit $$rc; }

.PHONY: build
build: lint $(BIT_FILE) ## Build bitstream from existing Vivado project

$(XPR):
	@printf "$(RED)Project not found at $(XPR). Run 'make setup' first.$(RESET)\n" >&2; exit 1

$(BIT_FILE): $(BUILD_INPUTS) | $(XPR)
	@printf "==> Building bitstream...\n"
	@$(VIVADO_RUN) bash -c "source /opt/Xilinx/Vivado/$(VIVADO_VERSION)/settings64.sh && cd /proj && vivado -mode batch -source $(TCL_SCRIPT)" && \
		printf "$(GREEN)SUCCESS! bitstream generated: $(BIT_FILE)$(RESET)\n" || \
		{ rc=$$?; printf "$(RED)FAIL! bitstream build failed$(RESET)\n"; exit $$rc; }

.PHONY: rebuild
rebuild: clean setup build ## Clean, recreate the Vivado project, and build the bitstream

.PHONY: clean
clean: ## Remove generated project files
	rm -rf "$(PROJ_DIR)/pynq_z2_rtl" "$(BIT_FILE)"
	rm -f "$(SIM_DIR)/soc.vvp" "$(SIM_DIR)/tb_soc.vcd" "$(SIM_DIR)/space_invaders.hex"

.PHONY: detect
detect: ## Detect connected JTAG boards via openFPGALoader
	openFPGALoader --detect

.PHONY: flash
flash: ## Flash the built bitstream to the PYNQ-Z2 over JTAG
	@if [ ! -f "$(BIT_FILE)" ]; then \
		echo "Bitstream not found at $(BIT_FILE). Run 'make build' first." >&2; \
		exit 1; \
	fi
	openFPGALoader -b $(BOARD) "$(BIT_FILE)"

.PHONY: all
all: build flash ## build bitstream, flash board

.PHONY: cold
cold: flash init ## Flash board and initialize PS7 after cold boot

.PHONY: init
init: ## Initialize PS7 over JTAG
	docker run --rm -it \
		-u "$$(id -u):$$(id -g)" \
		-e HOME=/tmp \
		--network host \
		--privileged \
		-v /dev/bus/usb:/dev/bus/usb \
		-v "$(INSTALL_DIR):/opt/Xilinx" \
		-v "$(PROJ_DIR):/proj" \
		-v "$(LICENSE_DIR):/root/.Xilinx" \
		-e XILINXD_LICENSE_FILE=/root/.Xilinx \
		$(IMAGE_NAME) bash -c "/opt/Xilinx/Vitis_Embedded/Vitis/$(VIVADO_VERSION)/bin/xsct -eval \
		'connect; targets -set -filter {name =~ \"APU\"}; \
		source /proj/pynq_z2_rtl/pynq_z2_rtl.gen/sources_1/bd/system/ip/system_processing_system7_0_0/ps7_init.tcl; \
		ps7_init; ps7_post_config'"

.PHONY: image
image: ## Build the Docker base image
	docker build -t $(IMAGE_NAME) .
