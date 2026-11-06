#!/bin/bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/lib/confirm.sh"
source "$script_dir/lib/chromium.sh"
source "$script_dir/lib/history.sh"
source "$script_dir/lib/node.sh"
set -o pipefail

if step_done claude.install; then
    echo "Claude はインストール済みです。"
elif command -v claude >/dev/null 2>&1; then
    step_record claude.install || exit 1
    echo "Claude はインストール済みです。"
elif confirm "Claude をインストールしますか？" --exit-on-cancel; then
    curl -fsSL https://claude.ai/install.sh | bash || exit 1
    claude --version || exit 1
    step_record claude.install || exit 1
fi

agents_source="$script_dir/../AGENTS.md"
agents_target="$HOME/.claude/CLAUDE.md"
if step_done claude.agents; then
    echo "Claude の AGENTS.md は設定済みです。"
elif [[ -f $agents_target ]] && [[ $(cat "$agents_target") == *"$(cat "$agents_source")"* ]]; then
    step_record claude.agents || exit 1
    echo "Claude の AGENTS.md は設定済みです。"
elif confirm "Claude の AGENTS.md に追記しますか？"; then
    mkdir -p "$(dirname "$agents_target")" || exit 1
    cat "$agents_source" >> "$agents_target" || exit 1
    step_record claude.agents || exit 1
fi

if step_done claude.linear; then
    echo "Claude の Linear MCP は設定済みです。"
elif claude mcp get linear >/dev/null 2>&1; then
    step_record claude.linear || exit 1
    echo "Claude の Linear MCP は設定済みです。"
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

if ! command -v npx >/dev/null 2>&1; then
    confirm "Node.js をインストールしますか？" --exit-on-cancel
    ensure_npx || exit 1
fi
step_record node.npx || exit 1

if step_done claude.playwright; then
    echo "Claude の Playwright MCP は設定済みです。"
elif claude mcp get playwright >/dev/null 2>&1; then
    step_record claude.playwright || exit 1
    echo "Claude の Playwright MCP は設定済みです。"
elif confirm "Claude に Playwright MCP を追加しますか？"; then
    claude mcp add --scope user playwright -- npx @playwright/mcp@latest || exit 1
    step_record claude.playwright || exit 1
fi
if step_done claude.playwright; then
    if step_done chromium.install; then
        echo "Chromium はインストール済みです。"
    elif chromium_installed; then
        step_record chromium.install || exit 1
        echo "Chromium はインストール済みです。"
    elif confirm "Chromium をインストールしますか？"; then
        install_chromium || exit 1
        step_record chromium.install || exit 1
    fi
fi
