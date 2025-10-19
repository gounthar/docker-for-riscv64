# Maintainer Guide

## GPG Package Signing

### Overview

The APT repository uses GPG signing to ensure package authenticity and integrity. All packages and repository metadata are signed with a dedicated GPG key.

**Current GPG Key:**
- Key ID: `56188341425B007407229B48FB1963FC3575A39D`
- Key Name: Docker RISC-V64 Repository
- Email: docker-riscv64-bot@noreply.github.com
- Fingerprint: `5618 8341 425B 0074 0722  9B48 FB19 63FC 3575 A39D`

### GPG Key Storage

The GPG private key is securely stored as a GitHub Actions secret:

- **Secret Name**: `GPG_PRIVATE_KEY`
- **Location**: Repository Settings → Secrets and variables → Actions
- **Format**: ASCII-armored private key
- **Usage**: Automatically imported during APT repository updates

### Automatic Signing Process

Package signing happens automatically in the `update-apt-repo.yml` workflow:

1. Workflow checks out apt-repo branch
2. GPG private key is imported from GitHub secrets
3. Packages are added to repository with `reprepro`
4. `reprepro` automatically signs packages using the imported key
5. Signed InRelease and Release.gpg files are generated
6. Changes are committed and pushed to apt-repo branch

### Verifying Signatures

Users verify package signatures by installing the public key:

```bash
wget -qO- https://github.com/gounthar/docker-for-riscv64/releases/download/gpg-key/docker-riscv64.gpg | \
  sudo tee /usr/share/keyrings/docker-riscv64.gpg > /dev/null
```

### GPG Key Rotation (If Needed)

If the GPG key needs to be rotated:

1. **Generate new GPG key:**
```bash
cat > gpg-gen-key.batch <<'EOF'
Key-Type: RSA
Key-Length: 4096
Name-Real: Docker RISC-V64 Repository
Name-Email: docker-riscv64-bot@noreply.github.com
Expire-Date: 0
%no-protection
%commit
EOF

gpg --batch --gen-key gpg-gen-key.batch
```

2. **Export keys:**
```bash
# Get the key ID
gpg --list-keys "Docker RISC-V64 Repository"

# Export private key (for GitHub secrets)
gpg --export-secret-keys --armor <KEY_ID> > private-key.asc

# Export public key (for users)
gpg --export --armor <KEY_ID> > public-key.asc
```

3. **Update GitHub secret:**
```bash
cat private-key.asc | gh secret set GPG_PRIVATE_KEY -R gounthar/docker-for-riscv64
```

4. **Update conf/distributions:**
```bash
# On apt-repo branch
git checkout apt-repo
# Edit conf/distributions and change SignWith: <NEW_KEY_ID>
git commit -m "chore: update GPG signing key"
git push
```

5. **Publish new public key:**
```bash
gh release edit gpg-key --notes "Updated GPG public key"
gh release upload gpg-key public-key.asc --clobber
```

6. **Notify users** to update their keyring

### Manual Signing (Emergency)

If automatic signing fails, manually sign the repository:

```bash
# On apt-repo branch
cd /tmp
git clone -b apt-repo https://github.com/gounthar/docker-for-riscv64 apt-repo
cd apt-repo

# Import your GPG key (if not already in keyring)
gpg --import /path/to/private-key.asc

# Export the repository (re-signs all packages)
reprepro -b . export trixie

# Verify signatures
gpg --verify dists/trixie/InRelease

# Commit and push
git add dists/
git commit -m "chore: re-sign repository"
git push origin apt-repo
```

## APT Repository Management

### Automatic Updates (Preferred)

The APT repository **should update automatically** when a new `.deb` package is built:

**Workflow**: `.github/workflows/update-apt-repo.yml`
**Trigger**: Automatically runs when "Build Debian Package" completes successfully

If the automation works:
1. New release is created (e.g., v28.5.1-riscv64)
2. Build Debian Package workflow runs → creates .deb
3. Update APT Repository workflow **automatically triggers**
4. Package is added to apt-repo branch
5. GitHub Pages deploys updated repository

### Manual Update (If Automation Fails)

If the automatic workflow doesn't trigger, manually update the repository:

```bash
# 1. Install reprepro (one-time)
sudo apt-get update && sudo apt-get install -y reprepro

# 2. Clone and prepare
cd /tmp
git clone -b apt-repo https://github.com/gounthar/docker-for-riscv64 apt-repo
cd apt-repo

# 3. Download the .deb package
RELEASE_TAG="v28.5.1-riscv64"  # Change to your release
gh release download $RELEASE_TAG -p "docker.io_*.deb" --repo gounthar/docker-for-riscv64

# 4. Add to repository
reprepro -b . includedeb trixie docker.io_*.deb

# 5. Verify
reprepro -b . list trixie

# 6. Commit and push
git add dists pool
git commit -m "Add docker.io from release $RELEASE_TAG"
git push origin apt-repo
```

### Using the Helper Script

A convenience script is available in the apt-repo branch:

```bash
cd /tmp/docker-for-riscv64-local
git checkout apt-repo
./add-package-to-apt-repo.sh
```

This script:
- Installs reprepro if needed
- Downloads the .deb
- Adds it to the repository
- Commits and pushes changes

## Release Checklist

### For Each New Docker Release

**Automatic path** (preferred):
1. ✅ Wait for moby release detection (daily check at 06:00 UTC)
2. ✅ Build automatically triggers
3. ✅ Binaries released
4. ✅ .deb package builds automatically
5. ✅ APT repository updates automatically
6. ✅ Done!

**Manual intervention needed if**:
- Automation fails (check GitHub Actions)
- Urgent release needed (trigger workflows manually)

### Triggering Workflows Manually

```bash
# Build from specific moby version
gh workflow run docker-weekly-build.yml -f moby_ref=v28.5.1

# Build Debian package (after binaries are released)
gh workflow run build-debian-package.yml -f release_tag=v28.5.1-riscv64

# Update APT repository (if automatic trigger fails)
# Currently requires manual process - see "Manual Update" section above
```

## Testing New Releases

### On RISC-V64 Hardware

After adding a package to the APT repository:

```bash
# 1. Install GPG key (if not already added)
wget -qO- https://github.com/gounthar/docker-for-riscv64/releases/download/gpg-key/docker-riscv64.gpg | \
  sudo tee /usr/share/keyrings/docker-riscv64.gpg > /dev/null

# 2. Add signed repository (if not already added)
echo "deb [arch=riscv64 signed-by=/usr/share/keyrings/docker-riscv64.gpg] https://gounthar.github.io/docker-for-riscv64 trixie main" | \
  sudo tee /etc/apt/sources.list.d/docker-riscv64.list

# 3. Update package list
sudo apt-get update

# 3. Check available version
apt-cache policy docker.io

# 4. Install or upgrade
sudo apt-get install docker.io
# or
sudo apt-get upgrade docker.io

# 5. Verify
docker --version
sudo systemctl status docker
```

### Quick Smoke Test

```bash
# Start Docker
sudo systemctl start docker

# Run hello-world (if available for riscv64)
sudo docker run hello-world

# Or use Alpine
sudo docker pull alpine
sudo docker run alpine echo "Docker on RISC-V64 works!"
```

## Troubleshooting

### APT Repository Not Updating

**Check GitHub Pages deployment**:
```bash
gh run list --repo gounthar/docker-for-riscv64 --workflow="pages-build-deployment"
```

**Check if workflow triggered**:
```bash
gh run list --repo gounthar/docker-for-riscv64 --limit 10
```

**Manually trigger page rebuild**:
- Go to Settings → Pages
- Select apt-repo branch again
- Save

### Package Installation Fails

**Check package availability**:
```bash
curl -s https://gounthar.github.io/docker-for-riscv64/dists/trixie/main/binary-riscv64/Packages
```

**Check repository metadata**:
```bash
curl -s https://gounthar.github.io/docker-for-riscv64/conf/distributions
```

**Clear APT cache**:
```bash
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
sudo apt-get update
```

## Repository Structure

```
apt-repo branch:
├── conf/
│   └── distributions       # Repository configuration
├── dists/                  # Generated by reprepro
│   └── trixie/
│       └── main/
│           └── binary-riscv64/
│               └── Packages    # Package index
├── pool/                   # Generated by reprepro
│   └── main/
│       └── d/
│           └── docker.io/
│               └── docker.io_*.deb
├── index.html             # Landing page
├── README.md              # Repository documentation
└── .gitignore            # Exclude db/ directory
```

## Maintenance Tasks

### Weekly
- ✅ Automatic builds run Sunday 02:00 UTC
- ✅ Check for new moby releases daily

### Monthly
- Review build logs for issues
- Check runner disk space
- Test APT installation on clean system

### As Needed
- Update Go version in workflows
- Update containerd/runc versions
- Add new Debian codenames (when new releases)

## Contact

**Maintainer**: Bruno Verachten (@gounthar)
**Repository**: https://github.com/gounthar/docker-for-riscv64
**Issues**: https://github.com/gounthar/docker-for-riscv64/issues
