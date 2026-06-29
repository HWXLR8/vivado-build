#!/usr/bin/env bash

set -euo pipefail

VIVADO_VERSION="2026.1"
INSTALL_DIR="${HOME}/xilinx-install"
PROJ_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/proj"
IMAGE_NAME="vivado-base:${VIVADO_VERSION}"

mkdir -p "${PROJ_DIR}"

docker run --rm -it \
    -v "${INSTALL_DIR}:/opt/Xilinx" \
    -v "${PROJ_DIR}:/proj" \
    "${IMAGE_NAME}" bash
