# Root Makefile for riscv64 integration
# This Makefile provides a riscv64 build target that wraps the custom build logic.
# Do not edit moby/Makefile directly; all custom logic should live outside the submodule.

.PHONY: riscv64

riscv64:
	@echo "Invoking riscv64 build script..."
	./build-docker-riscv64.sh
