FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    sudo wget locales lsb-release \
    libx11-6 libxext6 libxrender1 libxtst6 libxi6 libxrandr2 libxfixes3 \
    && locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV PATH="/opt/Xilinx/2026.1/Vivado/bin:${PATH}"
WORKDIR /proj
