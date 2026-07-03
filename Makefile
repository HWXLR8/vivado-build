SHELL := /bin/bash

# --- config ---
VIVADO_VERSION  := 2023.2
IMAGE_NAME      := vivado-base:$(VIVADO_VERSION)
INSTALL_DIR     := $(HOME)/xilinx-install
LICENSE_DIR     := $(HOME)/xilinx-license
PROJ_DIR        := $(CURDIR)/proj
TARBALL         := FPGAs_AdaptiveSoCs_Unified_2023.2_1013_2256.tar.gz
CONFIG_FILE     := install_config.txt
BOARD           := pynq_z2
BIT_FILE        := $(PROJ_DIR)/hello.bit
TCL_SCRIPT      := hello.tcl
VERILOG_SOURCES := $(wildcard $(PROJ_DIR)/*.v)

VIVADO_RUN = docker run --rm -it \
	--network host \
	-v "$(INSTALL_DIR):/opt/Xilinx" \
	-v "$(PROJ_DIR):/proj" \
	-v "$(LICENSE_DIR):/root/.Xilinx" \
	-v "$(HOME)/xilinx-install/Vitis_Embedded:/opt/Xilinx/Vitis_Embedded" \
	-e XILINXD_LICENSE_FILE=/root/.Xilinx \
	$(IMAGE_NAME)

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

.PHONY: install
install: ## Install Vivado via install.sh (builds image + installs, skips if already done)
	./install.sh

.PHONY: verify
verify: ## Confirm Vivado runs and print its version
	$(VIVADO_RUN) bash -c "source /opt/Xilinx/Vivado/$(VIVADO_VERSION)/settings64.sh && vivado -version"

.PHONY: shell
shell: ## Drop into an interactive shell inside the Vivado container
	$(VIVADO_RUN) bash

.PHONY: lint
lint: ## Check Verilog syntax with iverilog
	iverilog -tnull $(VERILOG_SOURCES)

.PHONY: build
build: lint ## Run synth -> place -> route -> bitstream via hello.tcl
	@mkdir -p "$(PROJ_DIR)"
	$(VIVADO_RUN) bash -c "source /opt/Xilinx/Vivado/$(VIVADO_VERSION)/settings64.sh && cd /proj && vivado -mode batch -source $(TCL_SCRIPT)"

.PHONY: clean
clean: ## Remove generated project files
	rm -rf "$(PROJ_DIR)/hello_proj" "$(BIT_FILE)"

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
all: install build flash ## Full pipeline: install Vivado, build bitstream, flash board

init: ## Initialize PS7 over JTAG
	docker run --rm -it \
		--network host \
		--privileged \
		-v /dev/bus/usb:/dev/bus/usb \
		-v "$(INSTALL_DIR):/opt/Xilinx" \
		-v "$(PROJ_DIR):/proj" \
		-v "$(LICENSE_DIR):/root/.Xilinx" \
		-e XILINXD_LICENSE_FILE=/root/.Xilinx \
		$(IMAGE_NAME) bash -c "/opt/Xilinx/Vitis_Embedded/Vitis/$(VIVADO_VERSION)/bin/xsct -eval \
		'connect; targets -set -filter {name =~ \"APU\"}; \
		source /proj/hello_proj/hello_proj.gen/sources_1/bd/system/ip/system_processing_system7_0_0/ps7_init.tcl; \
		ps7_init; ps7_post_config'"

.PHONY: image
image: ## Build the Docker base image
	docker build -t $(IMAGE_NAME) .
