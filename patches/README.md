# Patch Management for riscv64 Integration

- To add riscv64 to the E2E/integration test matrix, apply the patch in `patches/docker-bake.hcl.riscv64.patch` to `moby/docker-bake.hcl`.
- The GitHub Actions workflow dynamically reads platforms from the bake file, so no additional workflow patch is needed at this time.
- If the workflow changes in the future, add a patch for `.github/workflows/test.yml` here.
