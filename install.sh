#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]] || [[ "$1" != "vivado" && "$1" != "vitis" ]]; then
    echo "Usage: $0 [vivado|vitis]" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

MODE="$1"
VIVADO_VERSION="2023.2"
TARBALL="FPGAs_AdaptiveSoCs_Unified_2023.2_1013_2256.tar.gz"

INSTALL_DIR="${SCRIPT_DIR}/xilinx-install"
EXTRACTED_DIR="${SCRIPT_DIR}/tmp/xilinx-installer-${VIVADO_VERSION}"

IMAGE_NAME="vivado-base:${VIVADO_VERSION}"

if [[ "$MODE" == "vitis" ]]; then
    CONFIG_FILE="vitis_install_config.txt"
    SKIP_CHECK="${INSTALL_DIR}/Vitis_Embedded/Vitis/${VIVADO_VERSION}/bin/xsct"
    LIBS_SCRIPT="/opt/Xilinx/Vitis_Embedded/Vitis/${VIVADO_VERSION}/scripts/installLibs.sh"
else
    CONFIG_FILE="vivado_install_config.txt"
    SKIP_CHECK="${INSTALL_DIR}/Vivado/${VIVADO_VERSION}/bin/vivado"
    LIBS_SCRIPT="/opt/Xilinx/Vivado/${VIVADO_VERSION}/scripts/installLibs.sh"
fi

echo "==> Preparing install directory: ${INSTALL_DIR}"
mkdir -p "${INSTALL_DIR}"

if [[ -x "${SKIP_CHECK}" ]]; then
    echo "==> Already installed (${SKIP_CHECK} exists). Skipping."
    exit 0
fi

if [[ ! -f "${TARBALL}" ]]; then
    echo "ERROR: ${TARBALL} not found in ${SCRIPT_DIR}" >&2
    exit 1
fi

if [[ ! -f "${CONFIG_FILE}" ]]; then
    echo "ERROR: ${CONFIG_FILE} not found in ${SCRIPT_DIR}" >&2
    exit 1
fi

if [[ -f "${EXTRACTED_DIR}/xsetup" ]]; then
    echo "==> Installer already extracted, skipping decompression."
else
    echo "==> Decompressing tarball..."
    mkdir -p "${EXTRACTED_DIR}"
    tar -I pigz -xf "${TARBALL}" -C "${EXTRACTED_DIR}" --strip-components=1
fi

echo "==> Building base image (${IMAGE_NAME})..."
docker build -t "${IMAGE_NAME}" .

echo "==> Running ${MODE} installer inside container (this takes a while)..."
docker run --rm -i \
    -v "${EXTRACTED_DIR}:/tmp/installer:ro" \
    -v "${SCRIPT_DIR}/${CONFIG_FILE}:/tmp/install_config.txt:ro" \
    -v "${INSTALL_DIR}:/opt/Xilinx" \
    "${IMAGE_NAME}" bash -s <<INNER_SCRIPT
set -euo pipefail

/tmp/installer/xsetup --agree XilinxEULA,3rdPartyEULA -b Install -c /tmp/install_config.txt

sed -i 's/\r$//' "${LIBS_SCRIPT}"
"${LIBS_SCRIPT}"
INNER_SCRIPT

echo "==> Verifying..."
if [[ "$MODE" == "vitis" ]]; then
    docker run --rm \
        -v "${INSTALL_DIR}:/opt/Xilinx" \
        "${IMAGE_NAME}" \
        bash -c "/opt/Xilinx/Vitis_Embedded/Vitis/${VIVADO_VERSION}/bin/xsct -eval 'exit'"
else
    docker run --rm \
        -v "${INSTALL_DIR}:/opt/Xilinx" \
        "${IMAGE_NAME}" \
        bash -c "/opt/Xilinx/Vivado/${VIVADO_VERSION}/bin/vivado -version"
fi

echo "==> ${MODE} install complete."
