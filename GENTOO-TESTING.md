# Gentoo RISC-V64 Testing Guide

Comprehensive testing guide for Docker RISC-V64 overlay on Gentoo Linux.

## Prerequisites

### System Requirements

- **Architecture**: RISC-V64
- **Distribution**: Gentoo Linux (stage3 or full installation)
- **Kernel**: Linux 5.15+ with container support
- **Memory**: 2GB+ RAM recommended
- **Storage**: 10GB+ free space

### Required Kernel Options

Ensure your kernel has these options enabled:

```bash
# Check kernel config
zgrep -E 'CONFIG_(NAMESPACES|NET_NS|PID_NS|IPC_NS|UTS_NS|CGROUPS|CGROUP_CPUACCT|CGROUP_DEVICE|CGROUP_FREEZER|CGROUP_SCHED|CPUSETS|MEMCG|KEYS|VETH|BRIDGE|BRIDGE_NETFILTER|IP_NF_FILTER|IP_NF_TARGET_MASQUERADE|NETFILTER_XT_MATCH|NF_NAT|OVERLAY_FS|EXT4_FS|BTRFS_FS)' /proc/config.gz
```

Required options:
```
CONFIG_NAMESPACES=y
CONFIG_NET_NS=y
CONFIG_PID_NS=y
CONFIG_IPC_NS=y
CONFIG_UTS_NS=y
CONFIG_CGROUPS=y
CONFIG_CGROUP_CPUACCT=y
CONFIG_CGROUP_DEVICE=y
CONFIG_CGROUP_FREEZER=y
CONFIG_CGROUP_SCHED=y
CONFIG_CPUSETS=y
CONFIG_MEMCG=y
CONFIG_KEYS=y
CONFIG_VETH=y
CONFIG_BRIDGE=y
CONFIG_BRIDGE_NETFILTER=y
CONFIG_IP_NF_FILTER=y
CONFIG_IP_NF_TARGET_MASQUERADE=y
CONFIG_NETFILTER_XT_MATCH_ADDRTYPE=y
CONFIG_NETFILTER_XT_MATCH_CONNTRACK=y
CONFIG_NF_NAT=y
CONFIG_OVERLAY_FS=y
```

## Phase 1: Overlay Setup

### Step 1: Install Required Tools

```bash
# Install git and eselect-repository
emerge --ask dev-vcs/git app-eselect/eselect-repository

# Verify installation
eselect repository list
```

### Step 2: Add Docker RISC-V64 Overlay

```bash
# Add the overlay
eselect repository add docker-riscv64 git https://github.com/gounthar/docker-for-riscv64.git

# Sync the overlay
emerge --sync docker-riscv64

# Verify overlay is available
eselect repository list -i
```

Expected output:
```
docker-riscv64 [Git] https://github.com/gounthar/docker-for-riscv64.git
```

### Step 3: Verify Overlay Structure

```bash
# Check overlay location
ls -la /var/db/repos/docker-riscv64/

# Verify packages are visible
emerge --search docker | grep docker-riscv64
```

Expected packages:
- `app-containers/docker`
- `app-containers/containerd`
- `app-containers/runc`
- `app-containers/docker-cli`
- `app-containers/docker-compose`
- `sys-process/tini`

## Phase 2: Package Installation Testing

### Test 1: Install Individual Components

Test modular installation:

```bash
# Install containerd first
emerge --ask --verbose app-containers/containerd

# Verify containerd installation
which containerd
containerd --version

# Install runc
emerge --ask --verbose app-containers/runc

# Verify runc installation
which runc
runc --version

# Install docker-cli
emerge --ask --verbose app-containers/docker-cli

# Verify docker-cli installation
which docker
docker --version
```

### Test 2: Install Complete Docker System

```bash
# Install main docker package (pulls in all dependencies)
emerge --ask --verbose app-containers/docker

# Verify all binaries are installed
which dockerd docker-proxy containerd runc docker

# Check versions
dockerd --version
containerd --version
runc --version
docker --version
```

### Test 3: Optional Components

```bash
# Install docker-compose plugin
emerge --ask --verbose app-containers/docker-compose

# Verify compose installation
docker compose version

# Install tini (if using --init flag)
USE="static" emerge --ask --verbose sys-process/tini

# Verify tini installation
which tini
tini --version
```

## Phase 3: Service Configuration

### Step 1: Configure Docker Daemon

```bash
# Review daemon configuration
cat /etc/docker/daemon.json

# Customize if needed (example)
cat > /etc/docker/daemon.json <<'EOF'
{
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
```

### Step 2: Start Docker Service

For **systemd**:
```bash
# Enable and start docker service
systemctl enable docker.service
systemctl start docker.service

# Check service status
systemctl status docker.service

# View logs
journalctl -u docker.service -f
```

For **OpenRC**:
```bash
# Add docker to default runlevel
rc-update add docker default

# Start docker service
rc-service docker start

# Check service status
rc-service docker status
```

### Step 3: Configure User Permissions

```bash
# Add your user to docker group
usermod -aG docker $USER

# Logout and login for group changes to take effect
# Or use: newgrp docker

# Verify group membership
groups $USER
```

## Phase 4: Functional Testing

### Test 1: Docker Daemon

```bash
# Check docker is running
docker info

# Verify RISC-V64 architecture
docker info | grep -i "Architecture\|OSArch"
```

Expected output should show `riscv64`.

### Test 2: Basic Container Operations

```bash
# Pull a test image (if available for riscv64)
docker pull busybox:latest 2>&1 || echo "Note: May need riscv64-specific images"

# Run a simple container
docker run --rm busybox:latest echo "Hello from RISC-V64!"

# List running containers
docker ps

# List all containers
docker ps -a
```

### Test 3: Container Lifecycle

```bash
# Create a container
docker create --name test-container busybox:latest sleep 3600

# Start the container
docker start test-container

# Execute command in container
docker exec test-container echo "Testing exec"

# Stop the container
docker stop test-container

# Remove the container
docker rm test-container

# Verify cleanup
docker ps -a | grep test-container
```

### Test 4: Network Testing

```bash
# Create a custom network
docker network create test-net

# List networks
docker network ls

# Inspect network
docker network inspect test-net

# Run container on custom network
docker run --rm --network=test-net busybox:latest ip addr

# Clean up
docker network rm test-net
```

### Test 5: Volume Testing

```bash
# Create a volume
docker volume create test-vol

# List volumes
docker volume ls

# Use volume in container
docker run --rm -v test-vol:/data busybox:latest sh -c "echo test > /data/test.txt && cat /data/test.txt"

# Inspect volume
docker volume inspect test-vol

# Clean up
docker volume rm test-vol
```

### Test 6: Build Testing

```bash
# Create a simple Dockerfile
mkdir -p /tmp/docker-test
cat > /tmp/docker-test/Dockerfile <<'EOF'
FROM busybox:latest
RUN echo "Built on RISC-V64!" > /test.txt
CMD cat /test.txt
EOF

# Build image
docker build -t test-build:latest /tmp/docker-test/

# Run built image
docker run --rm test-build:latest

# Clean up
docker rmi test-build:latest
rm -rf /tmp/docker-test
```

## Phase 5: Docker Compose Testing

### Test 1: Compose Plugin Verification

```bash
# Verify compose plugin is installed
docker compose version

# Check plugin location
ls -la /usr/libexec/docker/cli-plugins/docker-compose
```

### Test 2: Simple Compose Application

```bash
# Create test compose file
mkdir -p /tmp/compose-test
cat > /tmp/compose-test/compose.yml <<'EOF'
services:
  test:
    image: busybox:latest
    command: sh -c "echo 'Compose on RISC-V64!' && sleep 10"
EOF

# Run compose application
cd /tmp/compose-test
docker compose up -d

# Check services
docker compose ps

# View logs
docker compose logs

# Stop and remove
docker compose down

# Clean up
cd ~
rm -rf /tmp/compose-test
```

## Phase 6: Integration Testing

### Test 1: Multi-Container Application

```bash
mkdir -p /tmp/integration-test
cat > /tmp/integration-test/compose.yml <<'EOF'
services:
  web:
    image: busybox:latest
    command: sh -c "while true; do echo 'Web service running'; sleep 5; done"

  worker:
    image: busybox:latest
    command: sh -c "while true; do echo 'Worker running'; sleep 3; done"
EOF

cd /tmp/integration-test
docker compose up -d

# Monitor logs
docker compose logs -f --tail=20 &
LOGS_PID=$!
sleep 30
kill $LOGS_PID

# Clean up
docker compose down
cd ~
rm -rf /tmp/integration-test
```

### Test 2: Init Process Testing (with tini)

```bash
# Test tini as init process
docker run --rm --init busybox:latest ps aux

# Should show tini as PID 1
```

## Phase 7: Performance Testing

### Test 1: Container Startup Time

```bash
# Measure startup time
time docker run --rm busybox:latest echo "startup test"

# Repeat 10 times and average
for i in {1..10}; do
  time docker run --rm busybox:latest echo "test $i"
done 2>&1 | grep real
```

### Test 2: Image Pull Performance

```bash
# Remove existing image
docker rmi busybox:latest 2>/dev/null || true

# Time image pull
time docker pull busybox:latest
```

### Test 3: Build Performance

```bash
# Simple build test
cat > /tmp/Dockerfile.bench <<'EOF'
FROM busybox:latest
RUN for i in $(seq 1 100); do echo "iteration $i"; done > /test.log
EOF

# Time the build
time docker build -f /tmp/Dockerfile.bench -t build-bench:latest /tmp/

# Clean up
docker rmi build-bench:latest
rm /tmp/Dockerfile.bench
```

## Phase 8: Stability Testing

### Test 1: Long-Running Container

```bash
# Start long-running container
docker run -d --name stability-test busybox:latest sh -c "i=0; while true; do echo iteration \$i; i=\$(expr $i + 1); sleep 60; done"

# Monitor for 30 minutes
watch -n 60 "docker inspect stability-test | grep -A 5 State"

# After monitoring period, check logs
docker logs stability-test | tail -20

# Clean up
docker stop stability-test
docker rm stability-test
```

### Test 2: Resource Stress Test

```bash
# Run multiple containers simultaneously
for i in {1..10}; do
  docker run -d --name stress-$i busybox:latest sh -c "while true; do echo test; sleep 1; done"
done

# Monitor system resources
htop  # or top

# Check all containers are running
docker ps | grep stress-

# Clean up
for i in {1..10}; do
  docker stop stress-$i
  docker rm stress-$i
done
```

## Phase 9: Cleanup Testing

### Test 1: Image Cleanup

```bash
# List all images
docker images

# Remove unused images
docker image prune -a --force

# Verify cleanup
docker images
```

### Test 2: Container Cleanup

```bash
# List all containers
docker ps -a

# Remove all stopped containers
docker container prune --force

# Verify cleanup
docker ps -a
```

### Test 3: Volume Cleanup

```bash
# List all volumes
docker volume ls

# Remove unused volumes
docker volume prune --force

# Verify cleanup
docker volume ls
```

### Test 4: Network Cleanup

```bash
# List all networks
docker network ls

# Remove unused networks
docker network prune --force

# Verify cleanup (default networks should remain)
docker network ls
```

### Test 5: Complete System Cleanup

```bash
# Remove everything
docker system prune -a --volumes --force

# Verify minimal state
docker info | grep -E "Containers|Images|Volumes"
```

## Phase 10: Uninstallation Testing

### Test 1: Stop Services

```bash
# systemd
systemctl stop docker.service
systemctl disable docker.service

# OpenRC
rc-service docker stop
rc-update del docker default
```

### Test 2: Remove Packages

```bash
# Remove in reverse dependency order
emerge --deselect app-containers/docker-compose
emerge --deselect app-containers/docker
emerge --deselect app-containers/docker-cli
emerge --deselect app-containers/containerd
emerge --deselect app-containers/runc
emerge --deselect sys-process/tini

# Clean dependencies
emerge --depclean --ask
```

### Test 3: Verify Removal

```bash
# Check binaries are removed
which docker dockerd containerd runc docker-compose tini

# Should return "not found" for all
```

### Test 4: Clean Residual Data (Optional)

```bash
# Remove docker data directory
rm -rf /var/lib/docker

# Remove configuration
rm -rf /etc/docker

# Remove overlay
eselect repository remove docker-riscv64
rm -rf /var/db/repos/docker-riscv64
```

## Troubleshooting

### Issue: Kernel not supported

**Symptoms**: Docker fails to start with kernel-related errors.

**Solution**:
```bash
# Check required kernel modules
modprobe overlay
modprobe br_netfilter

# Verify modules loaded
lsmod | grep -E 'overlay|br_netfilter'

# Make persistent
cat >> /etc/modules-load.d/docker.conf <<EOF
overlay
br_netfilter
EOF
```

### Issue: Permission denied

**Symptoms**: Non-root user cannot access docker socket.

**Solution**:
```bash
# Check socket permissions
ls -la /var/run/docker.sock

# Add user to docker group
usermod -aG docker $USER

# Restart docker service
systemctl restart docker.service  # or rc-service docker restart

# Re-login or use
newgrp docker
```

### Issue: Cannot pull images

**Symptoms**: "no matching manifest for linux/riscv64"

**Solution**:
RISC-V64 image availability is limited. Either:
- Build your own images
- Use multiarch images that support riscv64
- Check Docker Hub for riscv64-specific tags

### Issue: Overlay filesystem errors

**Symptoms**: Storage driver errors.

**Solution**:
```bash
# Stop docker
systemctl stop docker.service

# Remove existing data
rm -rf /var/lib/docker

# Ensure overlay module loaded
modprobe overlay

# Start docker
systemctl start docker.service
```

## Reporting Issues

If you encounter issues during testing:

1. **Collect Information**:
   ```bash
   # System info
   uname -a
   emerge --info

   # Docker info
   docker info
   docker version

   # Logs
   journalctl -u docker.service -n 100 --no-pager
   ```

2. **Open Issue**: https://github.com/gounthar/docker-for-riscv64/issues

3. **Include**:
   - Hardware details (RISC-V64 board/CPU)
   - Gentoo version and profile
   - Kernel version and config
   - Error messages and logs
   - Steps to reproduce

## Success Criteria

All tests should pass for production-ready certification:

- ✅ Overlay setup successful
- ✅ All packages install without errors
- ✅ Service starts successfully
- ✅ Basic container operations work
- ✅ Network and volumes functional
- ✅ Docker Compose works correctly
- ✅ No memory leaks or crashes in stability tests
- ✅ Clean uninstallation possible

## Next Steps After Testing

Once testing is complete and successful:

1. Document any RISC-V64-specific issues found
2. Update README with Gentoo installation verified
3. Submit overlay to Gentoo GURU (if desired)
4. Announce to Gentoo RISC-V community
5. Create performance benchmark results document

---

**Document Version**: 1.0
**Last Updated**: 2025-11-01
**Maintainer**: gounthar@gmail.com
