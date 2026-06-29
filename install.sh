#!/usr/bin/env bash

set -euo pipefail

# --- config — edit these if your filenames/paths differ ---
VIVADO_VERSION="2026.1"
TARBALL="FPGAs_AdaptiveSoCs_Unified_SDI_2026.1_0616_1700.tar"
CONFIG_FILE="install_config.txt"
INSTALL_DIR="${HOME}/xilinx-install"
IMAGE_NAME="vivado-base:${VIVADO_VERSION}"
# ------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

if [[ ! -f "${TARBALL}" ]]; then
    echo "ERROR: ${TARBALL} not found in ${SCRIPT_DIR}" >&2
    exit 1
fi
if [[ ! -f "${CONFIG_FILE}" ]]; then
    echo "ERROR: ${CONFIG_FILE} not found in ${SCRIPT_DIR}" >&2
    exit 1
fi

echo "==> Building base image (${IMAGE_NAME})..."
docker build -t "${IMAGE_NAME}" .

echo "==> Preparing install directory: ${INSTALL_DIR}"
mkdir -p "${INSTALL_DIR}"

if [[ -x "${INSTALL_DIR}/${VIVADO_VERSION}/Vivado/bin/vivado" ]]; then
    echo "==> Vivado already installed at ${INSTALL_DIR}/${VIVADO_VERSION}. Skipping install step."
else
    echo "==> Running installer inside container (this takes a while)..."
    docker run --rm -i \
        -v "${SCRIPT_DIR}/${TARBALL}:/tmp/installer.tar:ro" \
        -v "${SCRIPT_DIR}/${CONFIG_FILE}:/tmp/install_config.txt:ro" \
        -v "${INSTALL_DIR}:/opt/Xilinx" \
        "${IMAGE_NAME}" bash -s <<'INNER_SCRIPT'
set -euo pipefail
mkdir -p /tmp/installer
tar -xf /tmp/installer.tar -C /tmp/installer --strip-components=1
/tmp/installer/xsetup --agree XilinxEULA,3rdPartyEULA -b Install -c /tmp/install_config.txt
rm -rf /tmp/installer

LIBS_SCRIPT="/opt/Xilinx/2026.1/Vivado/scripts/installLibs.sh"
sed -i 's/\r$//' "${LIBS_SCRIPT}"
"${LIBS_SCRIPT}"
INNER_SCRIPT
fi

echo "==> Verifying install..."
docker run --rm \
    -v "${INSTALL_DIR}:/opt/Xilinx" \
    "${IMAGE_NAME}" vivado -version

echo "==> Done. Vivado ${VIVADO_VERSION} is installed at ${INSTALL_DIR}"
echo "==> To use it, run: ./run.sh"
