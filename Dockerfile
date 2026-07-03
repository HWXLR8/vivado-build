FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    sudo wget locales lsb-release usbutils \
    libtinfo5 libncurses5 \
    libx11-6 libxext6 libxrender1 libxtst6 libxi6 libxrandr2 libxfixes3 \
    libpixman-1-0 libpng16-16 x11-utils xvfb pigz \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV PATH="/opt/Xilinx/Vivado/2023.2/bin:${PATH}"

WORKDIR /proj
