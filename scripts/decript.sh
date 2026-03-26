#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENCRYPTED_DIR="${DOTFILES_DIR}/encrypted"
OUTPUT_DIR="${DOTFILES_DIR}/target"
KEY_FILE="${DOTFILES_DIR}/.age-key.txt"

usage() {
    echo "Usage: $(basename "$0") [--output DIR]"
    echo "  --output, -o    Output root directory for decrypted files (default: ${DOTFILES_DIR}/target)"
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

echo -e "${BLUE}=== Dotfiles Installation Script ===${NC}\n"
echo -e "${YELLOW}Output directory: ${OUTPUT_DIR}${NC}\n"

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
    if [ -f "${KEY_FILE}" ]; then
        echo -e "${YELLOW}Using secret key from ${KEY_FILE}${NC}\n"
    else
        echo -e "${RED}Error: AGE_SECRET_KEY environment variable is not set and ${KEY_FILE} not found${NC}"
        exit 1
    fi
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

key_to_path() {
    local key="$1"
    local path="${key//__//}"
    if [ "${path}" = "root" ]; then
        path=""
    fi
    if [ ! "${path}" = "${path#.}" ]; then
        echo "${path}"
    else
        echo ".${path}"
    fi
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

    if [ -n "${AGE_SECRET_KEY:-}" ]; then
        echo "${AGE_SECRET_KEY}" | "${AGE_BIN}" --decrypt --identity - "${encrypted}" > "${target}"
    else
        "${AGE_BIN}" --decrypt --identity "${KEY_FILE}" "${encrypted}" > "${target}"
    fi
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
    if [ -n "${AGE_SECRET_KEY:-}" ]; then
        echo "${AGE_SECRET_KEY}" | "${AGE_BIN}" --decrypt --identity - "${encrypted}" | tar -xf - -C "${OUTPUT_DIR}" --warning=no-unknown-keyword
    else
        "${AGE_BIN}" --decrypt --identity "${KEY_FILE}" "${encrypted}" | tar -xf - -C "${OUTPUT_DIR}" --warning=no-unknown-keyword
    fi

    if [ -d "${target_dir}" ]; then
        chmod 700 "${target_dir}" || true
    fi

    echo -e "${GREEN}✓ Decrypted ${target_dir}/ (tar extract)${NC}"
}

cd "${ENCRYPTED_DIR}"
shopt -s nullglob

for encrypted_file in *.age; do
    [ -e "${encrypted_file}" ] || continue

    key="${encrypted_file%.age}"

    if [[ "${key}" == *.tar ]]; then
        key="${key%.tar}"
        rel="$(key_to_path "${key}")"
        target="${OUTPUT_DIR}/${rel}"
        decrypt_dir "${ENCRYPTED_DIR}/${encrypted_file}" "${target}"
    else
        rel="$(key_to_path "${key}")"
        target="${OUTPUT_DIR}/${rel}"
        decrypt_file "${ENCRYPTED_DIR}/${encrypted_file}" "${target}" "644"
    fi
done

echo -e "\n${GREEN}Done!${NC}\n"
