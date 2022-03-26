#!/usr/bin/bash
podman build -t kernel:latest .
podman create --name kernel kernel:latest
mkdir -p out
podman cp kernel:/kernel.zip out/InfinityBattery-$(date +"%Y%m%d-%H%M").zip
podman rm kernel
