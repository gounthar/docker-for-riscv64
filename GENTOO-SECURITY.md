# Docker RISC-V64 Security Hardening Guide for Gentoo

Comprehensive security hardening procedures for Docker on Gentoo RISC-V64 systems.

## Table of Contents

1. [Security Overview](#security-overview)
2. [System Hardening](#system-hardening)
3. [Docker Daemon Configuration](#docker-daemon-configuration)
4. [Container Security](#container-security)
5. [Network Security](#network-security)
6. [Image Security](#image-security)
7. [Logging and Monitoring](#logging-and-monitoring)
8. [Access Control](#access-control)
9. [Security Auditing](#security-auditing)
10. [Best Practices](#best-practices)

## Security Overview

### Threat Model

When running Docker on RISC-V64, consider:
- **Container Escape**: Attackers breaking out of container isolation
- **Privilege Escalation**: Gaining root access on host system
- **Resource Exhaustion**: DoS attacks via resource consumption
- **Image Vulnerabilities**: Compromised or malicious container images
- **Network Attacks**: Lateral movement between containers
- **Data Exposure**: Sensitive data leaking from containers

### Security Layers

Defense in depth approach:
1. **Host System Security** - Gentoo kernel hardening
2. **Docker Daemon Security** - Secure daemon configuration
3. **Container Runtime Security** - Secure defaults and profiles
4. **Network Isolation** - Firewall and network policies
5. **Access Controls** - User permissions and authentication
6. **Monitoring** - Audit logging and intrusion detection

## System Hardening

### Kernel Hardening

#### Enable Security Features

Edit `/etc/portage/make.conf`:
```bash
# Security-focused kernel features
CONFIG_SECURITY=y
CONFIG_SECCOMP=y
CONFIG_SECCOMP_FILTER=y
CONFIG_SECURITY_SELINUX=y          # or CONFIG_SECURITY_APPARMOR=y
CONFIG_DEFAULT_SECURITY_SELINUX=y  # or CONFIG_DEFAULT_SECURITY_APPARMOR=y
CONFIG_AUDIT=y
CONFIG_AUDITSYSCALL=y
```

#### Rebuild Kernel

```bash
# Configure kernel with security options
cd /usr/src/linux
make menuconfig

# Security options -> Enable:
# - NSA SELinux Support (or AppArmor)
# - Socket and Networking Security Hooks
# - Enable different security models
# - Enable seccomp

make -j$(nproc) && make modules_install && make install
```

### AppArmor Setup (Recommended for Gentoo)

```bash
# Install AppArmor
emerge -av sys-apps/apparmor sys-apps/apparmor-utils

# Enable AppArmor profiles
systemctl enable apparmor
systemctl start apparmor

# Load Docker profile
aa-enforce /etc/apparmor.d/docker
```

### Seccomp Profiles

Seccomp restricts syscalls available to containers:

```bash
# Verify seccomp support
grep CONFIG_SECCOMP /boot/config-$(uname -r)

# Should show:
# CONFIG_SECCOMP=y
# CONFIG_SECCOMP_FILTER=y
```

### User Namespaces

Enable user namespace remapping:

Edit `/etc/subuid` and `/etc/subgid`:
```
dockremap:100000:65536
```

Configure Docker daemon (see Docker Daemon Configuration section).

## Docker Daemon Configuration

### Secure daemon.json

Create/edit `/etc/docker/daemon.json`:

```json
{
  "icc": false,
  "log-level": "info",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true,
  "seccomp-profile": "/etc/docker/seccomp-default.json",
  "userns-remap": "dockremap",
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  },
  "iptables": true,
  "ip-forward": true,
  "ip-masq": true,
  "bridge": "none"
}
```

### Explanation of Security Settings

- **icc: false** - Disables inter-container communication by default
- **no-new-privileges: true** - Prevents containers from gaining additional privileges
- **seccomp-profile** - Restricts syscalls available to containers
- **userns-remap** - Maps container root to unprivileged host user
- **userland-proxy: false** - Uses iptables hairpin NAT (more secure)
- **live-restore: true** - Containers survive daemon restarts

### Custom Seccomp Profile

Create `/etc/docker/seccomp-default.json`:

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": [
    "SCMP_ARCH_RISCV64"
  ],
  "syscalls": [
    {
      "names": [
        "accept",
        "accept4",
        "access",
        "bind",
        "brk",
        "chdir",
        "clone",
        "close",
        "connect",
        "dup",
        "dup2",
        "dup3",
        "epoll_create",
        "epoll_create1",
        "epoll_ctl",
        "epoll_wait",
        "execve",
        "exit",
        "exit_group",
        "fcntl",
        "fstat",
        "futex",
        "getpid",
        "getuid",
        "geteuid",
        "getgid",
        "getegid",
        "listen",
        "mmap",
        "mprotect",
        "munmap",
        "open",
        "openat",
        "poll",
        "read",
        "recv",
        "recvfrom",
        "recvmsg",
        "rt_sigaction",
        "rt_sigprocmask",
        "rt_sigreturn",
        "send",
        "sendto",
        "sendmsg",
        "socket",
        "stat",
        "wait4",
        "write"
      ],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
```

Note: This is a minimal example. Expand based on your container requirements.

### TLS for Docker Socket

Secure Docker daemon socket with TLS:

```bash
# Generate CA and certificates
mkdir -p /etc/docker/certs
cd /etc/docker/certs

# Create CA
openssl genrsa -out ca-key.pem 4096
openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -out ca.pem

# Create server certificate
openssl genrsa -out server-key.pem 4096
openssl req -new -key server-key.pem -out server.csr
echo subjectAltName = DNS:localhost,IP:127.0.0.1 > extfile.cnf
openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -extfile extfile.cnf

# Create client certificate
openssl genrsa -out key.pem 4096
openssl req -new -key key.pem -out client.csr
echo extendedKeyUsage = clientAuth > extfile-client.cnf
openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out cert.pem -extfile extfile-client.cnf

# Set permissions
chmod 0400 ca-key.pem server-key.pem key.pem
chmod 0444 ca.pem server-cert.pem cert.pem
```

Update daemon.json:
```json
{
  "tls": true,
  "tlscacert": "/etc/docker/certs/ca.pem",
  "tlscert": "/etc/docker/certs/server-cert.pem",
  "tlskey": "/etc/docker/certs/server-key.pem",
  "tlsverify": true,
  "hosts": ["tcp://0.0.0.0:2376", "unix:///var/run/docker.sock"]
}
```

> **WARNING: Network Exposure Risk**
> 
> Binding the Docker daemon to `0.0.0.0:2376` exposes it to the entire network. While TLS provides encryption and authentication, this configuration should be combined with strict firewall rules.
> 
> **Required Firewall Configuration:**
> ```bash
> # Only allow Docker API access from trusted IPs
> iptables -A INPUT -p tcp --dport 2376 -s 192.168.1.0/24 -j ACCEPT
> iptables -A INPUT -p tcp --dport 2376 -j DROP
> ```
> 
> For local-only access, use `"hosts": ["tcp://127.0.0.1:2376", "unix:///var/run/docker.sock"]` instead.

## Container Security

### Run Containers as Non-Root

```bash
# Create non-root user in Dockerfile
FROM busybox:latest
RUN addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser appuser
USER appuser

# Or at runtime
docker run --user 1000:1000 busybox:latest
```

### Read-Only Root Filesystem

```bash
# Run with read-only root
docker run --read-only -v /tmp busybox:latest

# Or in docker-compose.yml
services:
  app:
    image: myapp:latest
    read_only: true
    tmpfs:
      - /tmp
```

### Resource Limits

```bash
# CPU limits
docker run --cpus=".5" busybox:latest

# Memory limits
docker run --memory="512m" --memory-swap="512m" busybox:latest

# PID limits
docker run --pids-limit=100 busybox:latest

# Combined
docker run \
  --cpus=".5" \
  --memory="512m" \
  --memory-swap="512m" \
  --pids-limit=100 \
  busybox:latest
```

### Capabilities

Drop all capabilities and add only needed ones:

```bash
# Drop all capabilities
docker run --cap-drop=ALL busybox:latest

# Add specific capabilities
docker run \
  --cap-drop=ALL \
  --cap-add=NET_BIND_SERVICE \
  busybox:latest
```

Common safe capabilities:
- `NET_BIND_SERVICE` - Bind to ports < 1024
- `CHOWN` - Change file ownership
- `DAC_OVERRIDE` - Bypass file permission checks
- `SETUID/SETGID` - Change UID/GID

**Never add**:
- `SYS_ADMIN` - Full administrative capabilities
- `SYS_MODULE` - Load kernel modules
- `SYS_RAWIO` - Raw I/O access

### Security Options

```bash
# AppArmor profile
docker run --security-opt apparmor=docker-default busybox:latest

# Seccomp profile
docker run --security-opt seccomp=/path/to/profile.json busybox:latest

# No new privileges
docker run --security-opt no-new-privileges:true busybox:latest

# Combined
docker run \
  --security-opt apparmor=docker-default \
  --security-opt no-new-privileges:true \
  --cap-drop=ALL \
  busybox:latest
```

## Network Security

### Default Bridge Network

Avoid using default bridge - create custom networks:

```bash
# Create isolated network
docker network create --driver bridge \
  --subnet=172.18.0.0/16 \
  --opt com.docker.network.bridge.name=docker1 \
  isolated-net

# Run container on isolated network
docker run --network=isolated-net busybox:latest
```

### Disable Inter-Container Communication

In daemon.json:
```json
{
  "icc": false
}
```

Enable communication between specific containers using custom networks:
```bash
# Create a custom network for containers that need to communicate
docker network create my-app-net

# Run containers on that network - they can reach each other by container name
docker run -d --name service-a --network=my-app-net myapp-a:latest
docker run -d --name service-b --network=my-app-net myapp-b:latest

# service-a can now access service-b via: http://service-b:port

### Network Policies with iptables

```bash
# Allow only HTTP/HTTPS egress
iptables -A DOCKER-USER -p tcp --dport 80 -j ACCEPT
iptables -A DOCKER-USER -p tcp --dport 443 -j ACCEPT
iptables -A DOCKER-USER -j DROP

# Allow traffic only between specific containers
iptables -A DOCKER-USER -s 172.18.0.2 -d 172.18.0.3 -j ACCEPT
iptables -A DOCKER-USER -s 172.18.0.3 -d 172.18.0.2 -j ACCEPT
iptables -A DOCKER-USER -j DROP
```

### Encrypted Overlay Network

For multi-host setups:

```bash
docker network create \
  --driver overlay \
  --opt encrypted \
  secure-overlay
```

## Image Security

### Image Scanning

```bash
# Scan images for vulnerabilities (requires external tools)
# Example with Trivy
emerge -a app-containers/trivy
trivy image busybox:latest
```

### Only Use Trusted Images

```bash
# Verify image signatures
docker trust inspect busybox:latest

# Enable content trust
export DOCKER_CONTENT_TRUST=1
docker pull busybox:latest
```

### Minimal Base Images

Use minimal images:
- `busybox` - 1-5 MB
- `alpine` - ~5 MB
- Distroless images

### Multi-Stage Builds

```dockerfile
# Build stage
FROM golang:1.21 AS builder
WORKDIR /app
COPY . .
RUN go build -o myapp

# Runtime stage (minimal)
FROM busybox:latest
COPY --from=builder /app/myapp /
USER 1000:1000
ENTRYPOINT ["/myapp"]
```

### Image Signing

```bash
# Initialize trust
docker trust key generate mykey
docker trust signer add --key mykey.pub myuser myimage

# Sign and push
docker trust sign myimage:tag
```

## Logging and Monitoring

### Centralized Logging

Configure syslog driver:
```json
{
  "log-driver": "syslog",
  "log-opts": {
    "syslog-address": "udp://localhost:514",
    "tag": "docker/{{.Name}}"
  }
}
```

### Audit Logging

Enable auditd:

```bash
# Install auditd
emerge -av sys-process/audit

# Add Docker audit rules
cat >> /etc/audit/rules.d/docker.rules <<'EOF'
-w /usr/bin/docker -k docker
-w /var/lib/docker -k docker
-w /etc/docker -k docker
-w /usr/lib/systemd/system/docker.service -k docker
-w /usr/lib/systemd/system/docker.socket -k docker
EOF

# Reload rules
augenrules --load

# Monitor
ausearch -k docker
```

### Container Monitoring

```bash
# Real-time stats
docker stats

# Inspect specific container
docker inspect container_name

# Monitor logs
docker logs -f container_name
```

## Access Control

### Docker Group Management

Minimize docker group membership:

```bash
# List docker group members
getent group docker

# Remove unnecessary users
gpasswd -d username docker
```

### Sudo Access Control

Allow specific docker commands via sudo:

```bash
# /etc/sudoers.d/docker-limited
username ALL=(root) NOPASSWD: /usr/bin/docker ps
username ALL=(root) NOPASSWD: /usr/bin/docker logs
username ALL=(root) NOPASSWD: /usr/bin/docker inspect
```

### SELinux/AppArmor Policies

Custom AppArmor profile for Docker:

```bash
# /etc/apparmor.d/docker-restricted
#include <tunables/global>

profile docker-restricted flags=(attach_disconnected,mediate_deleted) {
  #include <abstractions/base>

  deny @{PROC}/* w,
  deny /sys/[^f]*/** wklx,
  deny /sys/f[^s]*/** wklx,
  deny /sys/fs/[^c]*/** wklx,

  capability,
  file,
  umount,
  network,
}
```

Load profile:
```bash
apparmor_parser -r /etc/apparmor.d/docker-restricted
```

## Security Auditing

### Docker Bench Security

```bash
# Clone Docker Bench
git clone https://github.com/docker/docker-bench-security.git
cd docker-bench-security

# Run audit
./docker-bench-security.sh
```

### CIS Benchmarks

Follow CIS Docker Benchmark guidelines:
- https://www.cisecurity.org/benchmark/docker

Key areas:
1. Host Configuration
2. Docker Daemon Configuration
3. Docker Daemon Files
4. Container Images
5. Container Runtime
6. Docker Security Operations
7. Docker Swarm Configuration

### Regular Security Checks

Create audit script:

```bash
#!/bin/bash
# /usr/local/bin/docker-security-audit.sh

echo "=== Docker Security Audit ==="
echo "Date: $(date)"
echo ""

echo "1. Docker daemon running as root:"
ps aux | grep dockerd | grep -v grep

echo ""
echo "2. Docker socket permissions:"
ls -l /var/run/docker.sock

echo ""
echo "3. Privileged containers:"
docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: Privileged={{ .HostConfig.Privileged }}'

echo ""
echo "4. Containers with host network:"
docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: NetworkMode={{ .HostConfig.NetworkMode }}'

echo ""
echo "5. Containers with host PID:"
docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: PidMode={{ .HostConfig.PidMode }}'

echo ""
echo "6. Images without defined user:"
docker images --quiet | xargs docker inspect --format '{{ .Id }}: User={{ .Config.User }}'
```

Schedule with cron:
```bash
# /etc/cron.weekly/docker-audit
0 0 * * 0 /usr/local/bin/docker-security-audit.sh > /var/log/docker-audit.log 2>&1
```

## Best Practices

### Container Lifecycle

1. **Build Time**:
   - Use minimal base images
   - Scan for vulnerabilities
   - Sign images
   - Remove unnecessary tools
   - Don't include secrets

2. **Runtime**:
   - Run as non-root
   - Drop capabilities
   - Enable seccomp/AppArmor
   - Set resource limits
   - Use read-only filesystem
   - Enable no-new-privileges

3. **Maintenance**:
   - Regular image updates
   - Prune unused resources
   - Monitor logs
   - Audit configurations

### Security Checklist

- [ ] Kernel hardening enabled
- [ ] AppArmor/SELinux active
- [ ] Docker daemon runs with secure configuration
- [ ] TLS enabled for remote access
- [ ] User namespace remapping configured
- [ ] Default bridge network not used
- [ ] Inter-container communication disabled by default
- [ ] Containers run as non-root
- [ ] Capabilities dropped by default
- [ ] Resource limits set
- [ ] Seccomp profiles applied
- [ ] Image scanning in CI/CD pipeline
- [ ] Only trusted registries used
- [ ] Audit logging enabled
- [ ] Regular security audits scheduled
- [ ] Docker group membership minimized
- [ ] Firewall rules configured

### Emergency Response

If compromised:

1. **Isolate**:
   ```bash
   # Stop all containers
   docker stop $(docker ps -q)

   # Disable docker service
   systemctl stop docker
   ```

2. **Investigate**:
   ```bash
   # Check logs
   journalctl -u docker.service
   docker logs <container>

   # Check for suspicious activity
   docker diff <container>
   docker inspect <container>
   ```

3. **Remediate**:
   ```bash
   # Remove compromised containers
   docker rm -f $(docker ps -a -q)

   # Remove compromised images
   docker rmi $(docker images -q)

   # Clean system
   docker system prune -a --volumes --force
   ```

4. **Harden**:
   - Apply security updates
   - Review and tighten configurations
   - Change credentials
   - Update firewall rules

## References

- Docker Security Best Practices: https://docs.docker.com/engine/security/
- CIS Docker Benchmark: https://www.cisecurity.org/benchmark/docker
- Gentoo Security Handbook: https://wiki.gentoo.org/wiki/Security_Handbook
- NIST Container Security: https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-190.pdf
- AppArmor Documentation: https://gitlab.com/apparmor/apparmor/-/wikis/Documentation

---

**Document Version**: 1.0
**Last Updated**: 2025-11-01
**Maintainer**: gounthar@gmail.com
