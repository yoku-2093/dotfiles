#!/bin/bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/lib/confirm.sh"
source "$script_dir/lib/chrome.sh"
source "$script_dir/lib/history.sh"
source "$script_dir/lib/node.sh"
set -o pipefail

if step_confirm claude.install "Claude をインストールしますか？"; then
    curl -fsSL https://claude.ai/install.sh | bash || exit 1
    claude --version || exit 1
    step_record claude.install || exit 1
fi

agents_source="$script_dir/../AGENTS.md"
agents_target="$HOME/.claude/CLAUDE.md"
if step_confirm claude.agents "Claude の CLAUDE.md に追記しますか？"; then
    mkdir -p "$(dirname "$agents_target")" || exit 1
    cat "$agents_source" >> "$agents_target" || exit 1
    step_record claude.agents || exit 1
fi

if step_confirm claude.linear "Claude に Linear MCP を追加しますか？"; then
    claude mcp add --transport http --scope user linear https://mcp.linear.app/mcp || exit 1
    step_record claude.linear || exit 1
fi
if step_done claude.linear; then
    if step_confirm claude.linear_login "Claude の Linear MCP にログインしますか？"; then
        claude mcp login linear --no-browser || exit 1
        step_record claude.linear_login || exit 1
    fi
fi

if step_confirm node.npx "Node.js をインストールしますか？"; then
    install_node || exit 1
    step_record node.npx || exit 1
fi
load_nvm_if_needed

if step_confirm claude.playwright "Claude に Playwright MCP を追加しますか？"; then
    claude mcp add --scope user playwright -- npx @playwright/mcp@latest --browser chrome || exit 1
    step_record claude.playwright || exit 1
fi
if step_done claude.playwright; then
    if step_confirm chrome.install "Google Chrome をインストールしますか？"; then
        install_chrome || exit 1
        step_record chrome.install || exit 1
    fi
fi
