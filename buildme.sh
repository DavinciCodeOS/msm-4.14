#!/usr/bin/bash
podman build -t kernel:latest --format docker .
podman create --name kernel kernel:latest
mkdir -p out
podman cp kernel:/kernel.zip out/InfinityBattery-NoMagisk-$(date +"%m-%d-%y").zip
podman rm kernel
