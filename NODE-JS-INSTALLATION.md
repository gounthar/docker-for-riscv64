# Node.js Installation on RISC-V64 Runner

**Date**: 2025-10-18
**Machine**: BananaPi F3 (RISC-V64)
**OS**: Armbian 25.8.1 (Debian Trixie)

## Problem

GitHub Actions workflows were failing with:
```
Cannot find: node in PATH
```

**Root Cause**: Many GitHub Actions (like `actions/checkout@v4`) are written in JavaScript and require Node.js to execute. The self-hosted runner (github-act-runner) needs Node.js available in the PATH.

## Solution: Install Node.js from Debian Repositories

### Step 1: Check Availability

```bash
ssh user@runner-host "apt-cache search nodejs | grep -E '^nodejs '"
```

Output:
```
nodejs - evented I/O for V8 javascript - runtime executable
```

Node.js is available in Debian Trixie repositories!

### Step 2: Install Node.js and npm

```bash
ssh user@runner-host "sudo apt-get update && sudo apt-get install -y nodejs npm"
```

**Packages installed**: 362 packages (Node.js + dependencies)

**Installation details**:
- **Node.js version**: v20.19.2
- **npm version**: 9.2.0
- **Installation location**: `/usr/bin/node`, `/usr/bin/npm`
- **Total disk space**: ~253 MB

### Step 3: Verify Installation

```bash
ssh user@runner-host "node --version && npm --version"
```

Output:
```
v20.19.2
9.2.0
```

### Step 4: Test Workflow

The runner was already running and picked up Node.js automatically. No restart needed!

Triggered test workflow:
```bash
gh workflow run docker-weekly-build.yml
```

**Result**: ✅ Checkout step succeeded!

Before (without Node.js):
```
Cannot find: node in PATH
❌ Failure - Main Checkout repository
```

After (with Node.js):
```
⭐ Run Main Checkout repository
✓ Getting Git version info
✓ Initializing the repository
✓ Setting up auth
✓ Fetching the repository
✓ Checking out the ref
✓ Fetching submodules
```

The workflow now progresses past the checkout step. The subsequent submodule error is a workflow configuration issue, not a runner issue.

## Runner Service Status

The runner is NOT running as a systemd service. It's running as a foreground process:

```bash
ps aux | grep github-act-runner | grep -v grep
```

Output:
```
poddingue  160234  bash -c cd ~/github-act-runner-test && nohup ./github-act-runner run > runner.log 2>&1 &
poddingue  160235  ./github-act-runner run
```

**Location**: `~/github-act-runner-test/github-act-runner`

## Success Metrics

- ✅ Node.js v20.19.2 installed
- ✅ npm 9.2.0 installed
- ✅ Node.js in PATH
- ✅ Checkout action works
- ✅ JavaScript-based actions can now execute
- ✅ No runner restart required

## Alternative: Building Node.js from Source

If Node.js wasn't available in Debian repos, we would have needed to build from source:

```bash
# Download Node.js for RISC-V64
wget https://nodejs.org/dist/v20.11.0/node-v20.11.0-linux-riscv64.tar.xz
tar -xf node-v20.11.0-linux-riscv64.tar.xz
sudo cp -r node-v20.11.0-linux-riscv64/* /usr/local/

# Verify
node --version
npm --version
```

**But this was NOT needed** - Debian Trixie has excellent RISC-V64 support!

## Next Steps

1. ✅ Node.js installed and working
2. Update RUNNER-SETUP.md to include Node.js as prerequisite
3. Fix workflow submodule configuration (separate issue)

## Disk Space Impact

**Before**: Unknown
**After**: +253 MB for Node.js and dependencies
**Worth it**: Yes - enables ALL GitHub Actions to work!
