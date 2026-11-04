#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/lib/confirm.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/chromium.sh"

if confirm "Codex をインストールしますか？" --exit-on-cancel; then
    curl -fsSL https://chatgpt.com/codex/install.sh | sh
    codex --version
fi

if confirm "Codex の AGENTS.md に追記しますか？"; then
    cat ../AGENTS.md >>~/.codex/AGENTS.md
fi

if confirm "Codex に Linear MCP を追加しますか？"; then
    config="$HOME/.codex/config.toml"
    mkdir -p "$HOME/.codex"
    if [[ -f $config ]] && grep -Eq "^[[:space:]]*\\[[[:space:]]*[\"']?mcp_servers[\"']?[[:space:]]*\\.[[:space:]]*[\"']?linear[\"']?[[:space:]]*\\]" "$config"; then
        echo "Linear MCP の設定は既に存在します。"
    else
        printf '\n[mcp_servers.linear]\nurl = "https://mcp.linear.app/mcp"\n' >>"$config"
    fi
    codex mcp login linear --no-browser
fi

if confirm "Codex に Playwright MCP を追加し、必要なら Chromium をインストールしますか？"; then
    config="$HOME/.codex/config.toml"
    mkdir -p "$HOME/.codex"
    if [[ -f $config ]] && grep -Eq "^[[:space:]]*\\[[[:space:]]*[\"']?mcp_servers[\"']?[[:space:]]*\\.[[:space:]]*[\"']?playwright[\"']?[[:space:]]*\\]" "$config"; then
        echo "Playwright MCP の設定は既に存在します。"
    else
        printf '\n[mcp_servers.playwright]\ncommand = "npx"\nargs = ["@playwright/mcp@latest"]\n' >>"$config"
    fi
    if chromium_installed; then
        echo "Chromium はインストール済みです。"
    else
        install_chromium
    fi
fi
