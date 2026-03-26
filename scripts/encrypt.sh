#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENCRYPTED_DIR="${DOTFILES_DIR}/encrypted"
KEY_FILE="${DOTFILES_DIR}/.age-key.txt"
SOURCE_DIR="${DOTFILES_DIR}/source"

usage() {
    echo "Usage: $(basename "$0") [--source DIR]"
    echo "  --source, -s    Source directory to encrypt (default: ${DOTFILES_DIR}/source)"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--source)
            shift
            if [[ $# -eq 0 ]]; then
                echo -e "${RED}Error: --source requires a directory path${NC}"
                exit 1
            fi
            SOURCE_DIR="$1"
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown argument '$1'${NC}"
            usage
            exit 1
            ;;
    esac
    shift
done

mkdir -p "${SOURCE_DIR}"
SOURCE_DIR="$(cd "${SOURCE_DIR}" 2>/dev/null && pwd)" || {
    echo -e "${RED}Error: Source directory '${SOURCE_DIR}' does not exist${NC}"
    exit 1
}

if [[ "${SOURCE_DIR}" == "${HOME}" ]]; then
    echo -e "${YELLOW}Source directory is HOME: ${SOURCE_DIR}${NC}"
    read -r -p "Proceed with encrypting from HOME? [y/N] " confirm
    case "${confirm}" in
        y|Y|yes|YES)
            ;;
        *)
            echo -e "${YELLOW}Aborted.${NC}"
            exit 0
            ;;
    esac
fi

if [ -z "$(ls -A "${SOURCE_DIR}" 2>/dev/null)" ]; then
    echo -e "${RED}Error: Source directory is empty: ${SOURCE_DIR}${NC}"
    exit 1
fi

echo -e "${BLUE}=== Dotfiles Encryption Script ===${NC}\n"
echo -e "${YELLOW}Source directory: ${SOURCE_DIR}${NC}\n"

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
    exit 1
fi

if [ -n "${AGE_SECRET_KEY:-}" ]; then
    echo -e "${YELLOW}Using AGE_SECRET_KEY from environment...${NC}"
    PUBLIC_KEY_FROM_ENV=$(printf '%s\n' "${AGE_SECRET_KEY}" | "${AGE_KEYGEN_BIN}" -y 2>/dev/null)
    if [ -n "${PUBLIC_KEY_FROM_ENV}" ]; then
        {
            echo "# created: $(date -Iseconds)"
            echo "# public key: ${PUBLIC_KEY_FROM_ENV}"
            echo "${AGE_SECRET_KEY}"
        } > "${KEY_FILE}"
        echo -e "${GREEN}✓ Key file created from environment variable${NC}\n"
    else
        echo -e "${RED}Error: Invalid AGE_SECRET_KEY${NC}"
        exit 1
    fi
elif [ ! -f "${KEY_FILE}" ]; then
    echo -e "${YELLOW}Generating new age key pair...${NC}"
    "${AGE_KEYGEN_BIN}" -o "${KEY_FILE}"
    echo -e "${GREEN}✓ Age key pair generated${NC}\n"
else
    echo -e "${YELLOW}Using existing age key: ${KEY_FILE}${NC}\n"
fi

PUBLIC_KEY=$(grep "^# public key:" "${KEY_FILE}" | cut -d: -f2 | tr -d ' ')
if [ -z "${PUBLIC_KEY}" ]; then
    echo -e "${RED}Error: Could not extract public key from ${KEY_FILE}${NC}"
    exit 1
fi

mkdir -p "${ENCRYPTED_DIR}"

manifest_key() {
    local rel="$1"
    rel="${rel%/}"
    rel="${rel#./}"
    rel="${rel#/}"
    rel="${rel#\.}"
    rel="${rel//\//__}"
    if [ -z "${rel}" ]; then
        rel="root"
    fi
    echo "${rel}"
}

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

cd "${SOURCE_DIR}"
shopt -s dotglob nullglob

for item in *; do
    [ -e "${item}" ] || continue

    rel="${item}"
    key="$(manifest_key "${rel}")"
    source_path="${SOURCE_DIR}/${rel}"

    if [ -d "${source_path}" ]; then
        tar_file="/tmp/${key}-$$.tar"
        echo -e "Creating tar archive of ${rel}/ ..."
        COPYFILE_DISABLE=1 tar -cf "${tar_file}" -C "${SOURCE_DIR}" --exclude='._*' "${rel}"
        "${AGE_BIN}" --encrypt --armor --recipient "${PUBLIC_KEY}" --output "${ENCRYPTED_DIR}/${key}.tar.age" "${tar_file}"
        rm -f "${tar_file}"
        echo -e "${GREEN}✓ Encrypted to ${ENCRYPTED_DIR}/${key}.tar.age${NC}"
    else
        encrypt_file "${source_path}" "${ENCRYPTED_DIR}/${key}.age" "${rel}"
    fi
done

if [ -f "${DOTFILES_DIR}/.gitignore" ]; then
    if ! grep -q "^\.age-key\.txt$" "${DOTFILES_DIR}/.gitignore"; then
        echo ".age-key.txt" >> "${DOTFILES_DIR}/.gitignore"
    fi
else
    echo ".age-key.txt" > "${DOTFILES_DIR}/.gitignore"
fi

echo -e "\n${GREEN}Done!${NC}\n"
