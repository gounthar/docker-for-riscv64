# Docker RISC-V64 APT Repository

This branch contains the APT repository for Docker Engine on RISC-V64 architecture.

## Repository Structure

This is a Debian APT repository managed by `reprepro`:

- `conf/` - Repository configuration
- `dists/` - Distribution metadata and package indices
- `pool/` - Package pool (actual .deb files)

## For Users

To use this repository, add it to your system:

```bash
# Add repository
echo "deb [arch=riscv64] https://gounthar.github.io/docker-for-riscv64 trixie main" | \
  sudo tee /etc/apt/sources.list.d/docker-riscv64.list

# Update package list
sudo apt-get update

# Install docker.io
sudo apt-get install docker.io
```

## For Maintainers

### Adding Packages

```bash
# Clone this branch
git clone -b apt-repo https://github.com/gounthar/docker-for-riscv64 apt-repo
cd apt-repo

# Add a package
reprepro -b . includedeb trixie /path/to/docker.io_*.deb

# Commit and push
git add dists pool
git commit -m "Add docker.io X.Y.Z-1"
git push
```

### Removing Packages

```bash
# List packages
reprepro -b . list trixie

# Remove a package
reprepro -b . remove trixie docker.io

# Commit
git add dists pool
git commit -m "Remove docker.io X.Y.Z-1"
git push
```

## Automated Updates

The repository is automatically updated by the GitHub Actions workflow when new releases are published.

See `.github/workflows/update-apt-repo.yml` in the main branch.

## Package Signing

Currently, packages are not signed (`SignWith: no` in `conf/distributions`).

To enable signing, update the configuration and add a GPG key:

```
SignWith: yes
```

Then generate and publish a GPG key for the repository.
