#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENCRYPTED_DIR="${DOTFILES_DIR}/encrypted"
KEY_FILE="${DOTFILES_DIR}/.age-key.txt"

echo -e "${BLUE}=== Dotfiles Encryption Script ===${NC}\n"

# Find age binaries (check mise installation first, then system)
AGE_BIN=""
AGE_KEYGEN_BIN=""

if [ -f "${HOME}/.local/share/mise/installs/age/latest/age/age" ]; then
    AGE_BIN="${HOME}/.local/share/mise/installs/age/latest/age/age"
    AGE_KEYGEN_BIN="${HOME}/.local/share/mise/installs/age/latest/age/age-keygen"
elif command -v age &> /dev/null; then
    AGE_BIN="age"
    AGE_KEYGEN_BIN="age-keygen"
else
    echo -e "${RED}Error: age is not installed${NC}"
    echo "Please install age first:"
    echo "  - Using mise: mise install age"
    echo "  - Using apt: sudo apt install age"
    echo "  - From source: https://github.com/FiloSottile/age"
    exit 1
fi

# Generate age key if it doesn't exist
if [ ! -f "${KEY_FILE}" ]; then
    echo -e "${YELLOW}Generating new age key pair...${NC}"
    "${AGE_KEYGEN_BIN}" -o "${KEY_FILE}"
    echo -e "${GREEN}✓ Age key pair generated${NC}\n"
else
    echo -e "${YELLOW}Using existing age key: ${KEY_FILE}${NC}\n"
fi

# Extract public key
PUBLIC_KEY=$(grep "^# public key:" "${KEY_FILE}" | cut -d: -f2 | tr -d ' ')
if [ -z "${PUBLIC_KEY}" ]; then
    echo -e "${RED}Error: Could not extract public key from ${KEY_FILE}${NC}"
    exit 1
fi

echo -e "${BLUE}Public key: ${GREEN}${PUBLIC_KEY}${NC}\n"

# Create encrypted directory if it doesn't exist
mkdir -p "${ENCRYPTED_DIR}"

# Function to encrypt a file
encrypt_file() {
    local source="$1"
    local dest="$2"
    local description="$3"

    if [ ! -f "${source}" ]; then
        echo -e "${YELLOW}Warning: ${source} does not exist, skipping${NC}"
        return
    fi

    echo -e "Encrypting ${description}..."
    "${AGE_BIN}" --encrypt --armor --recipient "${PUBLIC_KEY}" --output "${dest}" "${source}"
    echo -e "${GREEN}✓ Encrypted to ${dest}${NC}"
}

# Encrypt .bashrc
encrypt_file "${HOME}/.bashrc" "${ENCRYPTED_DIR}/bashrc.age" ".bashrc"

# Encrypt .gitconfig
encrypt_file "${HOME}/.gitconfig" "${ENCRYPTED_DIR}/gitconfig.age" ".gitconfig"

# Encrypt .ssh directory (as tar archive)
if [ -d "${HOME}/.ssh" ]; then
    echo -e "Creating tar archive of .ssh directory..."
    SSH_TAR="/tmp/ssh-$$.tar"
    tar -cf "${SSH_TAR}" -C "${HOME}" .ssh
    echo -e "${GREEN}✓ Created tar archive${NC}"

    echo -e "Encrypting .ssh archive..."
    "${AGE_BIN}" --encrypt --armor --recipient "${PUBLIC_KEY}" --output "${ENCRYPTED_DIR}/ssh.tar.age" "${SSH_TAR}"
    rm -f "${SSH_TAR}"
    echo -e "${GREEN}✓ Encrypted to ${ENCRYPTED_DIR}/ssh.tar.age${NC}"
else
    echo -e "${YELLOW}Warning: ${HOME}/.ssh directory does not exist, skipping${NC}"
fi

echo -e "\n${GREEN}=== Encryption Complete ===${NC}\n"

# Display instructions for Gitpod Secrets
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Next Steps: Configure Gitpod/ONA Secrets                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${YELLOW}1. Copy the secret key below:${NC}\n"
SECRET_KEY=$(grep -v "^#" "${KEY_FILE}")
echo -e "${GREEN}${SECRET_KEY}${NC}\n"

echo -e "${YELLOW}2. Add to Gitpod/ONA Secrets:${NC}"
echo -e "   - Go to: ${BLUE}https://gitpod.io/user/variables${NC} (or your ONA settings)"
echo -e "   - Click 'New Variable'"
echo -e "   - Name: ${GREEN}AGE_SECRET_KEY${NC}"
echo -e "   - Value: ${GREEN}<paste the secret key above>${NC}"
echo -e "   - Scope: Set to your repositories (e.g., */dotfiles)"
echo ""

echo -e "${YELLOW}3. Configure Gitpod Dotfiles:${NC}"
echo -e "   - Go to: ${BLUE}https://gitpod.io/user/preferences${NC}"
echo -e "   - Set 'Dotfiles Repository' to your dotfiles repo URL"
echo ""

echo -e "${YELLOW}4. Commit and push encrypted files:${NC}"
echo -e "   ${GREEN}cd ${DOTFILES_DIR}${NC}"
echo -e "   ${GREEN}git add encrypted/${NC}"
echo -e "   ${GREEN}git commit -m 'Add encrypted dotfiles'${NC}"
echo -e "   ${GREEN}git push${NC}"
echo ""

echo -e "${RED}⚠️  IMPORTANT: Keep the key file (${KEY_FILE}) secure!${NC}"
echo -e "${RED}   Do NOT commit this file to git.${NC}"
echo -e "${RED}   Add it to .gitignore immediately.${NC}\n"

# Add .age-key.txt to .gitignore if not already there
if [ -f "${DOTFILES_DIR}/.gitignore" ]; then
    if ! grep -q "^\.age-key\.txt$" "${DOTFILES_DIR}/.gitignore"; then
        echo ".age-key.txt" >> "${DOTFILES_DIR}/.gitignore"
        echo -e "${GREEN}✓ Added .age-key.txt to .gitignore${NC}"
    fi
else
    echo ".age-key.txt" > "${DOTFILES_DIR}/.gitignore"
    echo -e "${GREEN}✓ Created .gitignore with .age-key.txt${NC}"
fi

echo -e "\n${GREEN}Done!${NC}\n"
