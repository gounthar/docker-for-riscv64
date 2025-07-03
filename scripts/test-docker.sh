#!/bin/bash
echo "Testing Docker installation..."
docker --version
docker compose version
echo "Testing RISC-V container..."
docker run --rm riscv64/debian:sid echo "Hello from RISC-V!"
echo "Listing available RISC-V images..."
docker images | grep riscv64
