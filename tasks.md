# Step-by-Step Plan to Add riscv64 Architecture Support

This plan is atomic, testable, and follows the updated coding and git workflow policy. Each task is focused on a single concern.

---

~~**1. Categorize the Request and Create a Feature Branch**~~  
- ~~Start: No branch for riscv64 work.~~  
- ~~End: Feature branch named `feature/add-riscv64-support` is created, and all subsequent work is performed on this branch.~~  
**[COMPLETED]**

---

~~**2. Audit for Existing riscv64 Support**~~  
- ~~Start: Unclear what riscv64 support exists.~~  
- ~~End: List of all files/scripts/configs mentioning or targeting riscv64, committed to the feature branch.~~  
**[COMPLETED]**

---

~~**3. Write a Failing Unit Test for riscv64 Build Script**~~  
- ~~Start: No test for riscv64 build script.~~  
- ~~End: Failing unit test (e.g., bats or Go test) for riscv64 build script, committed.~~  
**[COMPLETED]**

---

~~**4. Create Dockerfile.riscv64**~~  
- ~~Start: No `Dockerfile.riscv64`.~~  
- ~~End: `moby/Dockerfile.riscv64` exists and builds a minimal riscv64 binary (can be a stub), committed.~~  
**[COMPLETED]**

---

~~**5. Add/Adapt Patch Script for Dockerfile.riscv64**~~  
- ~~Start: No patching script for riscv64.~~  
- ~~End: Script (e.g., `scripts/dockerfile-riscv64-fix.sh`) exists and can patch/fix `Dockerfile.riscv64`, committed.~~  
**[COMPLETED]**

---

~~**6. Implement riscv64 Build Script**~~  
- ~~Start: No riscv64 build script.~~  
- ~~End: Script (e.g., `build-docker-riscv64.sh` in the root directory) exists and can invoke the build for riscv64, committed.~~  
**[COMPLETED]**

---

~~**7. Make Unit Test for riscv64 Build Script Pass**~~  
- ~~Start: Failing test for riscv64 build script.~~  
- ~~End: Test passes, committed.~~  
**[COMPLETED]**

---

~~**8. Add riscv64 Target to Makefile**~~  
- ~~Start: No riscv64 target in Makefile.~~  
- ~~End: `make riscv64` (or similar) is a valid target, committed.~~  
**[COMPLETED]**

---

~~**9. Add riscv64 Platform to docker-bake.hcl**~~  
- ~~Start: No riscv64 platform in bake config.~~  
- ~~End: riscv64 is listed as a build platform/group, committed.~~  
**[COMPLETED]**

---

~~**10. Add riscv64 to E2E/Integration Test Matrix**~~  
- ~~Start: riscv64 not tested in E2E.~~  
- ~~End: riscv64 is a selectable/tested architecture in E2E tests, committed.~~  
**[COMPLETED]**

---

~~**11. Add riscv64 to CI/CD Pipeline**~~  
- ~~Start: riscv64 not present in CI.~~  
- ~~End: riscv64 build/test job runs in CI (can be allowed to fail initially), committed.~~  
**[COMPLETED]**

---

~~**12. Document riscv64 Support in README**~~  
- ~~Start: No mention of riscv64 in docs.~~  
- ~~End: `README.riscv64.md` in the root documents riscv64 support, build instructions, and known issues, committed.~~  
**[COMPLETED]**

---

~~**13. Document riscv64 Testing in TESTING.md**~~  
- ~~Start: No riscv64 test instructions.~~  
- ~~End: `TESTING.riscv64.md` in the root documents riscv64 test instructions, committed.~~  
**[COMPLETED]**

---

~~**14. Manual Build and Test on riscv64**~~  
- ~~Start: riscv64 build/test unverified.~~  
- ~~End: riscv64 build/test has been run and results are documented (commit any scripts or logs as needed).~~  
**[COMPLETED]**

---

**15. Refactor/Polish riscv64 Integration**  
- Start: riscv64 support is functional but may be messy.  
- End: riscv64 support is clean, documented, and maintainable, committed.

---

**16. Output Branch and Commit Information**  
- For every change, output:  
  - "Working on branch: `feature/add-riscv64-support`"  
  - After each commit: "Committed on `feature/add-riscv64-support`: `commit-hash` - commit message"

---

**17. Wait for User Approval Before Merge**  
- Start: All changes are on the feature branch.  
- End: User tests and approves; branch is merged and deleted.

---

**18. Patch Dockerfiles and Build Scripts to Use trixie for riscv64**  
- Start: Dockerfiles and scripts use "bookworm" as the base, which is not available for riscv64.  
- End: All relevant Dockerfiles and scripts use "trixie" for riscv64 builds, with patches stored out-of-tree.

  - **18.1. Audit all Dockerfiles and scripts for "bookworm" usage**  
    - List all files that reference "bookworm" and are used in riscv64 builds.

  - **18.2. Create a patch for moby/Dockerfile to use trixie for riscv64**  
    - Patch moby/Dockerfile so that when building for riscv64, it uses "trixie" as the base image.

  - **18.3. Patch any other Dockerfiles (e.g., Dockerfile.riscv, Dockerfile.riscv-fixed) to use trixie**  
    - Ensure all riscv64-related Dockerfiles use "trixie".

  - **18.4. Patch build scripts to reference trixie where needed**  
    - Update scripts that may hardcode "bookworm" to use "trixie" for riscv64.

  - **18.5. Document the trixie transition in README.riscv64.md**  
    - Add a section explaining the need for trixie and how the patches work.

  - **18.6. Test the patched build process for riscv64**  
    - Attempt a build and document any further issues or required patches.

---

This plan is fully aligned with the updated coding and git workflow policy, ensuring atomic, testable steps and strict branch/commit hygiene.
