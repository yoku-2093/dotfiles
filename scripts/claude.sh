#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/lib/confirm.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/chromium.sh"

if confirm "Claude をインストールしますか？" --exit-on-cancel; then
    curl -fsSL https://claude.ai/install.sh | bash
    claude --version
fi

if confirm "Claude の AGENTS.md に追記しますか？"; then
    cat ../AGENTS.md >>~/.claude/CLAUDE.md
fi

if confirm "Claude に Linear MCP を追加しますか？"; then
    claude mcp add --transport http --scope user linear https://mcp.linear.app/mcp
    claude mcp login linear --no-browser
fi

if confirm "Claude に Playwright MCP を追加し、必要なら Chromium をインストールしますか？"; then
    claude mcp add --scope user playwright -- npx @playwright/mcp@latest
    if chromium_installed; then
        echo "Chromium はインストール済みです。"
    else
        install_chromium
    fi
fi

