#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/lib/confirm.sh"

if confirm "Codex をインストールしますか？" --exit-on-cancel; then
    curl -fsSL https://chatgpt.com/codex/install.sh | sh
    codex --version
fi

if confirm "Codex の AGENTS.md に追記しますか？"; then
    cat ../AGENTS.md >>~/.codex/AGENTS.md
fi

if confirm "Codex に Linear MCP を追加しますか？"; then
    codex mcp add linear --url https://mcp.linear.app/mcp
    codex mcp login linear --no-browser
fi
