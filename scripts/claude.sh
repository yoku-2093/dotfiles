#!/bin/bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/lib/confirm.sh"
source "$script_dir/lib/chromium.sh"
source "$script_dir/lib/history.sh"
source "$script_dir/lib/node.sh"
set -o pipefail

if step_done claude.install; then
    echo "Claude のインストールは過去に完了したためスキップします。"
elif confirm "Claude をインストールしますか？" --exit-on-cancel; then
    curl -fsSL https://claude.ai/install.sh | bash || exit 1
    claude --version || exit 1
    step_record claude.install || exit 1
fi

agents_source="$script_dir/../AGENTS.md"
agents_target="$HOME/.claude/CLAUDE.md"
if step_done claude.agents; then
    echo "Claude の AGENTS.md は過去に完了したためスキップします。"
elif confirm "Claude の AGENTS.md に追記しますか？"; then
    mkdir -p "$(dirname "$agents_target")" || exit 1
    cat "$agents_source" >> "$agents_target" || exit 1
    step_record claude.agents || exit 1
fi

if step_done claude.linear; then
    echo "Claude の Linear MCP は過去に完了したためスキップします。"
elif confirm "Claude に Linear MCP を追加しますか？"; then
    claude mcp add --transport http --scope user linear https://mcp.linear.app/mcp || exit 1
    step_record claude.linear || exit 1
fi
if step_done claude.linear && ! step_done claude.linear_login; then
    if confirm "Claude の Linear MCP にログインしますか？"; then
        claude mcp login linear --no-browser || exit 1
        step_record claude.linear_login || exit 1
    fi
fi

if step_done node.npx; then
    echo "Node.js のインストールは過去に完了したためスキップします。"
elif confirm "Node.js をインストールしますか？" --exit-on-cancel; then
    install_node || exit 1
    step_record node.npx || exit 1
fi
load_nvm_if_needed

if step_done claude.playwright; then
    echo "Claude の Playwright MCP は過去に完了したためスキップします。"
elif confirm "Claude に Playwright MCP を追加しますか？"; then
    claude mcp add --scope user playwright -- npx @playwright/mcp@latest || exit 1
    step_record claude.playwright || exit 1
fi
if step_done claude.playwright; then
    if step_done chromium.install; then
        echo "Chromium は過去に完了したためスキップします。"
    elif confirm "Chromium をインストールしますか？"; then
        install_chromium || exit 1
        step_record chromium.install || exit 1
    fi
fi
