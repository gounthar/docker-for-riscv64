# BuildKit Container Registry Strategy

**Created:** 2025-12-09
**Status:** Recommended Approach Defined
**Related Issues:** #207, #208, #210

> **Note:** This document contains project-specific URLs and usernames for the docker-for-riscv64 repository.
> When forking or adapting, replace `gounthar` with your GitHub username.

## Executive Summary

**Recommendation:** Use GitHub Container Registry (ghcr.io) as the primary container registry for BuildKit RISC-V64 images.

**Registry URL:** `ghcr.io/<github-username>/buildkit-riscv64`

## Evaluation Criteria

When choosing a container registry for BuildKit RISC-V64 images, we evaluated:

1. **Integration with existing infrastructure** (GitHub Actions, GitHub Releases)
2. **Public accessibility** (users can pull without authentication)
3. **Authentication simplicity** (CI/CD integration)
4. **Cost** (free tier availability)
5. **Bandwidth and storage** (limits and pricing)
6. **Multi-architecture support** (future amd64/arm64 builds)
7. **OCI compatibility** (standard container formats)

## Option 1: GitHub Container Registry (ghcr.io) - RECOMMENDED

### Pros

**Seamless Integration:**
- Native GitHub Actions authentication via `GITHUB_TOKEN`
- No additional secrets or configuration needed
- Same organization/user namespace as source repository

**Public Access:**
- Images can be marked as public (no authentication needed for pull)
- Users can pull with: `docker pull ghcr.io/gounthar/buildkit-riscv64:latest`
- No login required for consumers

**Free and Generous:**
- Unlimited public images
- Generous bandwidth allocation (500MB/month for private, unlimited for public)
- No storage limits for public images

**Developer Experience:**
- Integrated with GitHub Packages UI
- Versioning tied to git tags
- Easy to find alongside source code

**Multi-Architecture Ready:**
- Supports Docker manifest lists for multi-arch images
- Can add amd64/arm64 variants in the future

### Cons

**Limited Discoverability:**
- Not as discoverable as Docker Hub
- Users must know the GitHub organization

**GitHub Dependency:**
- Tied to GitHub ecosystem
- Account suspension affects registry access

### Implementation

```bash
# CI/CD Authentication (automatic in GitHub Actions)
echo "$GITHUB_TOKEN" | docker login ghcr.io -u ${{ github.actor }} --password-stdin

# Tag images
docker tag buildkit:latest ghcr.io/gounthar/buildkit-riscv64:latest
docker tag buildkit:v0.14.0 ghcr.io/gounthar/buildkit-riscv64:v0.14.0-riscv64

# Push images
docker push ghcr.io/gounthar/buildkit-riscv64:latest
docker push ghcr.io/gounthar/buildkit-riscv64:v0.14.0-riscv64

# User pull (no authentication needed if public)
docker pull ghcr.io/gounthar/buildkit-riscv64:latest
```

### Configuration Required

1. **Make package public:**
   - After first push, go to: https://github.com/users/gounthar/packages/container/buildkit-riscv64/settings
   - Change visibility to "Public"
   - Allows unauthenticated pulls

2. **Workflow permissions:**
   - Already configured in workflow: `packages: write`

## Option 2: Docker Hub

### Pros

**Maximum Discoverability:**
- Most popular container registry
- Search at https://hub.docker.com
- Official Docker ecosystem integration

**Established Platform:**
- Trusted by Docker community
- Well-documented
- Native `docker pull` destination

### Cons

**Authentication Complexity:**
- Requires separate Docker Hub account
- Must configure `DOCKERHUB_TOKEN` secret
- Additional credential management

**Rate Limits:**
- Anonymous pulls limited to 100 per 6 hours
- Authenticated pulls limited to 200 per 6 hours (free tier)
- Can impact users pulling images

**Naming Constraints:**
- Requires organization or personal namespace
- `docker pull gounthar/buildkit-riscv64` (personal namespace)
- OR `docker pull riscv64/buildkit` (requires organization)

**Storage Limits:**
- Free tier: 1 private repository, unlimited public repositories
- Image retention policies may delete old images

### Implementation

```bash
# CI/CD Authentication (requires secret)
echo "$DOCKERHUB_TOKEN" | docker login -u gounthar --password-stdin

# Tag images
docker tag buildkit:latest gounthar/buildkit-riscv64:latest
docker tag buildkit:v0.14.0 gounthar/buildkit-riscv64:v0.14.0

# Push images
docker push gounthar/buildkit-riscv64:latest
docker push gounthar/buildkit-riscv64:v0.14.0

# User pull (subject to rate limits)
docker pull gounthar/buildkit-riscv64:latest
```

## Option 3: Self-Hosted Registry

### Pros

**Complete Control:**
- No external dependencies
- No rate limits or quotas
- Custom retention policies

**Cost Control:**
- Pay only for infrastructure
- Predictable costs

### Cons

**Operational Overhead:**
- Requires server maintenance
- SSL certificate management
- Backup and disaster recovery
- Security patching
- High availability setup

**Infrastructure Costs:**
- Server hosting fees
- Bandwidth costs
- Storage costs

**Complexity:**
- Authentication configuration
- Network configuration (firewalls, DNS)
- Not suitable for open-source public images

**Not Recommended:** Too much overhead for an open-source project.

## Option 4: Quay.io (Red Hat)

### Pros

**Security Focus:**
- Built-in vulnerability scanning
- Image signing support
- Security notifications

**Free Tier:**
- Unlimited public repositories
- Good community support

### Cons

**Less Common:**
- Fewer Docker users familiar with Quay
- Additional registry to manage

**Authentication:**
- Requires separate Quay.io account
- Additional secret configuration

**Not Recommended:** Benefits don't outweigh GitHub Container Registry advantages.

## Comparison Matrix

| Feature | GitHub Container Registry | Docker Hub | Self-Hosted | Quay.io |
|---------|---------------------------|------------|-------------|---------|
| **Integration** | Excellent (GitHub Actions) | Good | Manual | Good |
| **Public Access** | Yes (after config) | Yes | Configurable | Yes |
| **Authentication** | Automatic (GITHUB_TOKEN) | Manual (secret) | Manual | Manual (secret) |
| **Cost** | Free (unlimited public) | Free (with limits) | Infrastructure cost | Free (unlimited public) |
| **Rate Limits** | None for public | 100-200 pulls/6h | None | Minimal |
| **Discoverability** | Medium | High | Low | Low |
| **Maintenance** | None | None | High | None |
| **Multi-Arch** | Yes | Yes | Yes | Yes |
| **Recommendation** | ✅ **Recommended** | Alternative | ❌ Not Suitable | Alternative |

## Selected Strategy: GitHub Container Registry

### Reasoning

1. **Zero Configuration Overhead:** Automatic authentication via GITHUB_TOKEN
2. **Project Alignment:** Repository and images in same namespace
3. **No Cost:** Unlimited public images with generous bandwidth
4. **Future-Proof:** Supports multi-arch manifests for future expansion
5. **Developer Friendly:** Integrated GitHub UI for package management

### Image Naming Convention

- **Repository:** `ghcr.io/gounthar/buildkit-riscv64`
- **Latest tag:** `ghcr.io/gounthar/buildkit-riscv64:latest` (tracks master branch)
- **Version tags:** `ghcr.io/gounthar/buildkit-riscv64:v0.14.0-riscv64` (official releases)
- **Development tags:** `ghcr.io/gounthar/buildkit-riscv64:master-20251209` (dev builds)

### User Documentation

Users can pull the image with:

```bash
# Pull latest
docker pull ghcr.io/gounthar/buildkit-riscv64:latest

# Pull specific version
docker pull ghcr.io/gounthar/buildkit-riscv64:v0.14.0-riscv64

# Use with Docker Buildx
docker buildx create \
  --name riscv-builder \
  --driver docker-container \
  --driver-opt image=ghcr.io/gounthar/buildkit-riscv64:latest \
  --use
```

### Alternative Registry Support

If needed in the future, we can mirror images to Docker Hub:

```bash
# Pull from GHCR
docker pull ghcr.io/gounthar/buildkit-riscv64:v0.14.0-riscv64

# Tag for Docker Hub
docker tag ghcr.io/gounthar/buildkit-riscv64:v0.14.0-riscv64 gounthar/buildkit-riscv64:v0.14.0

# Push to Docker Hub
docker push gounthar/buildkit-riscv64:v0.14.0
```

This allows us to start with GHCR and expand to Docker Hub based on user demand.

## Implementation Checklist

- [x] Create workflow with GHCR integration
- [x] Configure `packages: write` permission
- [ ] After first build, make package public (manual GitHub UI step)
- [ ] Test unauthenticated pull
- [ ] Update README.md with GHCR pull instructions
- [ ] Document Docker Buildx integration with GHCR image
- [ ] Monitor GitHub Container Registry usage and limits

## Security Considerations

### Image Signing

Consider implementing image signing in the future:
- Use Cosign for container image signing
- Provides supply chain security
- Users can verify image authenticity

### Vulnerability Scanning

GitHub Container Registry provides:
- Automatic security scanning with GitHub Security Advisories
- Vulnerability notifications
- Dependency graph analysis

### Access Control

- Workflow uses `GITHUB_TOKEN` (automatic, scoped, time-limited)
- No long-lived credentials in secrets
- Package visibility set to public (no authentication needed for pulls)

## Future Enhancements

### Multi-Architecture Manifest

When/if we build for multiple architectures:

```bash
# Create manifest list
docker manifest create ghcr.io/gounthar/buildkit-riscv64:v0.14.0 \
  ghcr.io/gounthar/buildkit-riscv64:v0.14.0-riscv64 \
  ghcr.io/gounthar/buildkit-riscv64:v0.14.0-amd64 \
  ghcr.io/gounthar/buildkit-riscv64:v0.14.0-arm64

# Push manifest
docker manifest push ghcr.io/gounthar/buildkit-riscv64:v0.14.0
```

Users can then pull the appropriate architecture automatically:
```bash
docker pull ghcr.io/gounthar/buildkit-riscv64:v0.14.0  # Pulls correct arch
```

### Alternative: Docker Hub Mirror

If user demand requires Docker Hub presence:

1. Create automated mirroring workflow
2. Trigger on GHCR push events
3. Re-tag and push to Docker Hub
4. Maintain both registries with same versions

## References

- GitHub Container Registry docs: https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry
- Docker Hub rate limits: https://docs.docker.com/docker-hub/download-rate-limit/
- Docker manifest lists: https://docs.docker.com/engine/reference/commandline/manifest/
- Cosign image signing: https://github.com/sigstore/cosign

## Conclusion

**GitHub Container Registry (ghcr.io)** is the optimal choice for BuildKit RISC-V64 images due to:
- Zero-configuration GitHub Actions integration
- Unlimited free public hosting
- Native multi-architecture support
- Seamless developer experience

This decision aligns with the project's existing GitHub-centric infrastructure while providing the best user experience for pulling BuildKit images.
