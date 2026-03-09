#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENCRYPTED_DIR="${DOTFILES_DIR}/encrypted"
MANIFEST_FILE="${DOTFILES_DIR}/dotfiles.manifest"
OUTPUT_DIR="${DOTFILES_DIR}/target"

usage() {
    echo "Usage: $(basename "$0") [--output DIR] [--manifest FILE]"
    echo "  --output, -o    Output root directory for decrypted files (default: ${DOTFILES_DIR}/target)"
    echo "  --manifest, -m  Manifest file path (default: ${DOTFILES_DIR}/dotfiles.manifest)"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output)
            shift
            if [[ $# -eq 0 ]]; then
                echo -e "${RED}Error: --output requires a directory path${NC}"
                exit 1
            fi
            OUTPUT_DIR="$1"
            ;;
        -m|--manifest)
            shift
            if [[ $# -eq 0 ]]; then
                echo -e "${RED}Error: --manifest requires a file path${NC}"
                exit 1
            fi
            MANIFEST_FILE="$1"
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

mkdir -p "${OUTPUT_DIR}"
OUTPUT_DIR="$(cd "${OUTPUT_DIR}" 2>/dev/null && pwd)" || {
    echo -e "${RED}Error: Output directory '${OUTPUT_DIR}' does not exist${NC}"
    exit 1
}

if [ ! -f "${MANIFEST_FILE}" ]; then
    echo -e "${RED}Error: Manifest file not found: ${MANIFEST_FILE}${NC}"
    exit 1
fi

echo -e "${BLUE}=== Dotfiles Installation Script ===${NC}\n"
echo -e "${YELLOW}Output directory: ${OUTPUT_DIR}${NC}"
echo -e "${YELLOW}Manifest file: ${MANIFEST_FILE}${NC}"
echo -e "${YELLOW}Backup directory: disabled${NC}\n"

AGE_BIN=""
if [ -f "${HOME}/.local/share/mise/installs/age/latest/age/age" ]; then
    AGE_BIN="${HOME}/.local/share/mise/installs/age/latest/age/age"
elif command -v age &> /dev/null; then
    AGE_BIN="age"
else
    echo -e "${RED}Error: age is not installed${NC}"
    exit 1
fi

if [ -z "${AGE_SECRET_KEY:-}" ]; then
    echo -e "${RED}Error: AGE_SECRET_KEY environment variable is not set${NC}"
    exit 1
fi

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

decrypt_file() {
    local encrypted="$1"
    local target="$2"
    local permissions="$3"

    if [ ! -f "${encrypted}" ]; then
        echo -e "${YELLOW}Warning: ${encrypted} does not exist, skipping${NC}"
        return
    fi

    mkdir -p "$(dirname "${target}")"

    echo "${AGE_SECRET_KEY}" | "${AGE_BIN}" --decrypt --identity - "${encrypted}" > "${target}"
    chmod "${permissions}" "${target}"
    echo -e "${GREEN}✓ Decrypted ${target}${NC}"
}

decrypt_dir() {
    local encrypted="$1"
    local target_dir="$2"

    if [ ! -f "${encrypted}" ]; then
        echo -e "${YELLOW}Warning: ${encrypted} does not exist, skipping${NC}"
        return
    fi

    mkdir -p "${OUTPUT_DIR}"
    echo "${AGE_SECRET_KEY}" | "${AGE_BIN}" --decrypt --identity - "${encrypted}" | tar -xf - -C "${OUTPUT_DIR}"

    if [ -d "${target_dir}" ]; then
        chmod 700 "${target_dir}" || true
    fi

    echo -e "${GREEN}✓ Decrypted ${target_dir}/ (tar extract)${NC}"
}

while IFS= read -r raw_line || [ -n "${raw_line}" ]; do
    line="${raw_line%%#*}"
    line="$(echo "${line}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    [ -z "${line}" ] && continue

    rel="${line%/}"
    rel="${rel#./}"
    rel="${rel#/}"
    [ -z "${rel}" ] && continue

    key="$(manifest_key "${rel}")"
    target="${OUTPUT_DIR}/${rel}"

    if [[ "${line}" == */ ]]; then
        decrypt_dir "${ENCRYPTED_DIR}/${key}.tar.age" "${target}"
    else
        decrypt_file "${ENCRYPTED_DIR}/${key}.age" "${target}" "644"
    fi
done < "${MANIFEST_FILE}"

echo -e "\n${GREEN}Done!${NC}\n"
