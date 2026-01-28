#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENCRYPTED_DIR="${DOTFILES_DIR}/encrypted"
BACKUP_DIR="${HOME}/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

echo -e "${BLUE}=== Dotfiles Installation Script ===${NC}\n"

# Find age binary (check mise installation first, then system)
AGE_BIN=""

if [ -f "${HOME}/.local/share/mise/installs/age/latest/age/age" ]; then
    AGE_BIN="${HOME}/.local/share/mise/installs/age/latest/age/age"
elif command -v age &> /dev/null; then
    AGE_BIN="age"
else
    echo -e "${RED}Error: age is not installed${NC}"
    echo "Please install age first:"
    echo "  - Using mise: mise install age"
    echo "  - Using apt: sudo apt install age"
    echo "  - From source: https://github.com/FiloSottile/age"
    exit 1
fi

# Check if AGE_SECRET_KEY environment variable is set
if [ -z "${AGE_SECRET_KEY:-}" ]; then
    echo -e "${RED}Error: AGE_SECRET_KEY environment variable is not set${NC}"
    echo ""
    echo "Please configure Gitpod/ONA Secrets:"
    echo "  1. Go to: https://gitpod.io/user/variables (or your ONA settings)"
    echo "  2. Add a new variable:"
    echo "     Name: AGE_SECRET_KEY"
    echo "     Value: <your age secret key>"
    echo "     Scope: */dotfiles (or appropriate scope)"
    echo ""
    echo "Or export it manually for testing:"
    echo "  export AGE_SECRET_KEY='<your-secret-key>'"
    exit 1
fi

# Create backup directory
mkdir -p "${BACKUP_DIR}"
echo -e "${YELLOW}Backup directory: ${BACKUP_DIR}${NC}\n"

# Function to decrypt a file
decrypt_file() {
    local encrypted="$1"
    local target="$2"
    local description="$3"
    local permissions="$4"

    if [ ! -f "${encrypted}" ]; then
        echo -e "${YELLOW}Warning: ${encrypted} does not exist, skipping${NC}"
        return
    fi

    echo -e "Decrypting ${description}..."

    # Backup existing file if it exists
    if [ -f "${target}" ]; then
        cp -p "${target}" "${BACKUP_DIR}/$(basename "${target}")"
        echo -e "${YELLOW}  ✓ Backed up existing file to ${BACKUP_DIR}${NC}"
    fi

    # Decrypt file
    echo "${AGE_SECRET_KEY}" | "${AGE_BIN}" --decrypt --identity - "${encrypted}" > "${target}"

    # Set permissions
    chmod "${permissions}" "${target}"

    echo -e "${GREEN}✓ Decrypted to ${target} (permissions: ${permissions})${NC}"
}

# Function to decrypt and extract tar archive
decrypt_and_extract_tar() {
    local encrypted="$1"
    local target_dir="$2"
    local description="$3"

    if [ ! -f "${encrypted}" ]; then
        echo -e "${YELLOW}Warning: ${encrypted} does not exist, skipping${NC}"
        return
    fi

    echo -e "Decrypting and extracting ${description}..."

    # Backup existing directory if it exists
    if [ -d "${target_dir}" ]; then
        cp -rp "${target_dir}" "${BACKUP_DIR}/$(basename "${target_dir}")"
        echo -e "${YELLOW}  ✓ Backed up existing directory to ${BACKUP_DIR}${NC}"
    fi

    # Create target directory if it doesn't exist
    mkdir -p "${target_dir}"

    # Decrypt and extract tar archive
    echo "${AGE_SECRET_KEY}" | "${AGE_BIN}" --decrypt --identity - "${encrypted}" | tar -xf - -C "${HOME}"

    echo -e "${GREEN}✓ Decrypted and extracted to ${target_dir}${NC}"
}

# Decrypt .bashrc
decrypt_file \
    "${ENCRYPTED_DIR}/bashrc.age" \
    "${HOME}/.bashrc" \
    ".bashrc" \
    "644"

# Decrypt .gitconfig
decrypt_file \
    "${ENCRYPTED_DIR}/gitconfig.age" \
    "${HOME}/.gitconfig" \
    ".gitconfig" \
    "644"

# Decrypt and extract .ssh directory
decrypt_and_extract_tar \
    "${ENCRYPTED_DIR}/ssh.tar.age" \
    "${HOME}/.ssh" \
    ".ssh directory"

# Ensure .ssh directory has correct permissions
if [ -d "${HOME}/.ssh" ]; then
    chmod 700 "${HOME}/.ssh"

    # Set correct permissions for SSH files
    [ -f "${HOME}/.ssh/github" ] && chmod 600 "${HOME}/.ssh/github"
    [ -f "${HOME}/.ssh/github.pub" ] && chmod 644 "${HOME}/.ssh/github.pub"
    [ -f "${HOME}/.ssh/config" ] && chmod 644 "${HOME}/.ssh/config"
    [ -f "${HOME}/.ssh/known_hosts" ] && chmod 644 "${HOME}/.ssh/known_hosts"

    echo -e "${GREEN}✓ Set proper permissions for .ssh directory and files${NC}"
fi

echo -e "\n${GREEN}=== Installation Complete ===${NC}\n"

echo -e "${BLUE}Installed files:${NC}"
[ -f "${HOME}/.bashrc" ] && echo -e "  ${GREEN}✓${NC} ~/.bashrc"
[ -f "${HOME}/.gitconfig" ] && echo -e "  ${GREEN}✓${NC} ~/.gitconfig"
[ -d "${HOME}/.ssh" ] && echo -e "  ${GREEN}✓${NC} ~/.ssh/"

echo -e "\n${YELLOW}Backup location: ${BACKUP_DIR}${NC}"

# Test SSH connection (optional, non-blocking)
if [ -f "${HOME}/.ssh/github" ]; then
    echo -e "\n${BLUE}Testing GitHub SSH connection...${NC}"
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        echo -e "${GREEN}✓ GitHub SSH authentication successful${NC}"
    else
        echo -e "${YELLOW}⚠ GitHub SSH test inconclusive (this may be normal)${NC}"
    fi
fi

echo -e "\n${GREEN}Done!${NC}\n"
