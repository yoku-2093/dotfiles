#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/lib/confirm.sh"

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
