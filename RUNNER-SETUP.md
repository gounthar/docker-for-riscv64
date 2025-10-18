# GitHub Actions Self-Hosted Runner Setup for RISC-V64

**Complete guide for setting up github-act-runner on RISC-V64 hardware**

## Overview

This document describes how we set up a self-hosted GitHub Actions runner on a BananaPi F3 (RISC-V64) for automated Docker builds.

**Why github-act-runner?**
- Official GitHub Actions runner doesn't support RISC-V64 yet
- .NET (required for official runner) has experimental RISC-V support
- github-act-runner is written in Go (excellent RISC-V support!)
- Compatible with GitHub Actions workflows

## Prerequisites

- RISC-V64 machine (we used BananaPi F3)
- Debian Trixie or similar (riscv64)
- Go 1.24+ installed
- Docker installed
- GitHub repository admin access

## Setup Steps

### 1. Install Dependencies

```bash
# Verify Go is installed
go version
# Should show: go version go1.24.4 linux/riscv64

# Verify Docker is installed  
docker --version
```

### 2. Clone and Build github-act-runner

```bash
cd ~
git clone https://github.com/ChristopherHX/github-act-runner.git github-act-runner-test
cd github-act-runner-test

# Build the runner (takes ~2-3 minutes)
go build -v -o github-act-runner .

# Verify build
./github-act-runner --help
```

**Expected output:**
- Binary size: ~25MB
- All commands available (configure, run, svc, etc.)

### 3. Get Registration Token

Go to your repository settings:
```
https://github.com/YOUR_USERNAME/YOUR_REPO/settings/actions/runners/new
```

You'll see a command like:
```bash
./config.sh --url https://github.com/YOUR_USERNAME/YOUR_REPO --token AAA...
```

Copy the token value.

### 4. Configure Runner

```bash
./github-act-runner configure \
  --url https://github.com/YOUR_USERNAME/YOUR_REPO \
  --token YOUR_TOKEN_HERE \
  --name bananapi-f3-runner \
  --labels riscv64,self-hosted,linux \
  --work _work
```

**Success:** You should see `success` output.

**Verify registration:**
```bash
gh api repos/YOUR_USERNAME/YOUR_REPO/actions/runners --jq '.runners[].name'
```

### 5. Test Runner Manually

```bash
# Start runner in foreground (for testing)
./github-act-runner run
```

You should see:
```
Listening for Jobs: bananapi-f3-runner ( https://github.com/YOUR_USERNAME/YOUR_REPO )
```

**Check status on GitHub:**
```bash
gh api repos/YOUR_USERNAME/YOUR_REPO/actions/runners --jq '.runners[] | {name, status, busy}'
```

Should show: `"status": "online"`

### 6. Create Systemd Service

```bash
# Create service file
sudo tee /etc/systemd/system/github-runner.service << 'EOFService'
[Unit]
Description=GitHub Actions Runner (RISC-V64)
After=network.target docker.service
Wants=network.target

[Service]
Type=simple
User=poddingue
WorkingDirectory=/home/poddingue/github-act-runner-test
ExecStart=/home/poddingue/github-act-runner-test/github-act-runner run
Restart=always
RestartSec=10
KillMode=process
KillSignal=SIGTERM
TimeoutStopSec=5min

[Install]
WantedBy=multi-user.target
EOFService

# Reload systemd
sudo systemctl daemon-reload

# Enable auto-start
sudo systemctl enable github-runner

# Start service
sudo systemctl start github-runner

# Check status
sudo systemctl status github-runner
```

### 7. Verify Service

```bash
# Check logs
sudo journalctl -u github-runner -f

# Check runner status
systemctl status github-runner
```

## Testing the Runner

### Create Test Workflow

Create `.github/workflows/test-runner.yml`:

```yaml
name: Test RISC-V Runner

on:
  workflow_dispatch:

jobs:
  test:
    runs-on: [self-hosted, riscv64]
    
    steps:
      - name: Check architecture
        run: uname -m
      
      - name: Check Go version
        run: go version
      
      - name: Check Docker version
        run: docker --version
      
      - name: System info
        run: |
          echo "Host: $(hostname)"
          echo "User: $(whoami)"
          echo "Disk: $(df -h ~ | tail -1)"
          echo "CPU: $(nproc)"
```

### Run Test

```bash
# Trigger workflow
gh workflow run test-runner.yml

# Watch progress
gh run watch
```

## Production Workflows

We created three automated workflows:

### 1. Weekly Docker Builds

**File:** `.github/workflows/docker-weekly-build.yml`

- Runs every Sunday at 02:00 UTC
- Manual trigger with custom moby ref
- Builds Docker Engine binaries
- Creates GitHub releases automatically
- ~30-40 minutes on BananaPi F3

**Manual trigger:**
```bash
gh workflow run docker-weekly-build.yml
# Or with specific moby version:
gh workflow run docker-weekly-build.yml -f moby_ref=v27.5.1
```

### 2. Moby Release Tracking

**File:** `.github/workflows/track-moby-releases.yml`

- Checks daily for new Moby releases
- Creates issues for new releases
- Prevents duplicate builds

**Manual trigger:**
```bash
gh workflow run track-moby-releases.yml
```

### 3. Runner Update Tracking

**File:** `.github/workflows/track-runner-releases.yml`

- Checks daily for runner updates  
- Creates update issues with instructions
- Monitors current runner version

**Manual trigger:**
```bash
gh workflow run track-runner-releases.yml
```

## Maintenance

### Update Runner

```bash
cd ~/github-act-runner-test
git pull
go build -v -o github-act-runner .
sudo systemctl restart github-runner
```

### View Logs

```bash
# Real-time logs
sudo journalctl -u github-runner -f

# Recent logs
sudo journalctl -u github-runner -n 100

# Runner application log
tail -f ~/github-act-runner-test/runner.log
```

### Restart Runner

```bash
sudo systemctl restart github-runner
```

### Stop Runner

```bash
sudo systemctl stop github-runner
```

## Troubleshooting

### Runner Shows Offline

**Check service status:**
```bash
systemctl status github-runner
```

**Check logs:**
```bash
sudo journalctl -u github-runner -n 50
```

**Common issues:**
- Network connectivity
- Docker daemon not running
- Authentication token expired (90 days)

**Solution:**
```bash
# Restart runner
sudo systemctl restart github-runner

# If token expired, reconfigure:
cd ~/github-act-runner-test
./github-act-runner remove
./github-act-runner configure --url ... --token NEW_TOKEN
sudo systemctl start github-runner
```

### Build Failures

**Check runner logs:**
```bash
tail -100 ~/github-act-runner-test/runner.log
```

**Check workflow logs:**
```bash
gh run list --limit 5
gh run view RUN_ID
```

### Out of Disk Space

**Check space:**
```bash
df -h ~
docker system df
```

**Clean up:**
```bash
# Clean Docker
docker system prune -a

# Clean old builds
cd ~/docker-for-riscv64
rm -rf moby/bundles/
git clean -fdx moby/
```

## Performance Notes

**BananaPi F3 (RISC-V64) Build Times:**
- Test workflow: ~5 seconds
- Docker binary build: ~8 minutes  
- Full Docker dev image: ~25 minutes
- Weekly build (complete): ~35-40 minutes

**Resource Usage:**
- CPU: 4 cores, moderate usage
- RAM: 2-4GB during builds
- Disk: ~5GB per build (cleaned after)

## Security Considerations

1. **Runner runs as user `poddingue`**
   - Not root for security
   - Has Docker access (docker group)

2. **Network access**
   - Runner needs internet for GitHub API
   - Firewall: allow outbound HTTPS

3. **Authentication**
   - Token expires after 90 days
   - Stored in runner config (~/.runner)

4. **Workflow permissions**
   - Self-hosted runners can access:
     - Repository code
     - GitHub secrets
     - Docker daemon
   - Only use for trusted repositories!

## References

- **github-act-runner:** https://github.com/ChristopherHX/github-act-runner
- **GitHub Actions:** https://docs.github.com/en/actions
- **Self-hosted runners:** https://docs.github.com/en/actions/hosting-your-own-runners

## Success Metrics

✅ **Runner Status:** Online  
✅ **Test Workflow:** Passing  
✅ **Weekly Builds:** Automated  
✅ **Release Tracking:** Active  
✅ **Uptime:** 99%+ expected  

---

**Last Updated:** 2025-10-18  
**Author:** Claude Code  
**Hardware:** BananaPi F3 (RISC-V64)  
**Repository:** https://github.com/gounthar/docker-for-riscv64
