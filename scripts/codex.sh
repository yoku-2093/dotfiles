#!/bin/bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/lib/confirm.sh"
source "$script_dir/lib/chromium.sh"
source "$script_dir/lib/history.sh"
source "$script_dir/lib/node.sh"
set -o pipefail

config="$HOME/.codex/config.toml"
agents_source="$script_dir/../AGENTS.md"
agents_target="$HOME/.codex/AGENTS.md"

mcp_configured() {
    [[ -f $config ]] && grep -Eq "^[[:space:]]*\\[[[:space:]]*[\"']?mcp_servers[\"']?[[:space:]]*\\.[[:space:]]*[\"']?$1[\"']?[[:space:]]*\\]" "$config"
}

if step_done codex.install; then
    echo "Codex のインストールは完了済みです。"
elif command -v codex >/dev/null 2>&1; then
    step_record codex.install || exit 1
    echo "Codex はインストール済みです。"
elif confirm "Codex をインストールしますか？" --exit-on-cancel; then
    if ! curl -fsSL https://chatgpt.com/codex/install.sh | sh; then
        echo "Codex のインストールに失敗しました。" >&2
        exit 1
    fi
    codex --version || exit 1
    step_record codex.install || exit 1
fi

if step_done codex.agents; then
    echo "Codex の AGENTS.md は設定済みです。"
elif [[ -f $agents_target ]] && [[ $(cat "$agents_target") == *"$(cat "$agents_source")"* ]]; then
    step_record codex.agents || exit 1
    echo "Codex の AGENTS.md は設定済みです。"
elif confirm "Codex の AGENTS.md に追記しますか？"; then
    mkdir -p "$(dirname "$agents_target")"
    cat "$agents_source" >>"$agents_target" || exit 1
    step_record codex.agents || exit 1
fi

if step_done codex.linear; then
    echo "Linear MCP の設定は完了済みです。"
elif mcp_configured linear; then
    step_record codex.linear || exit 1
    echo "Linear MCP の設定は既に存在します。"
elif confirm "Codex に Linear MCP を追加しますか？"; then
    mkdir -p "$(dirname "$config")"
    printf '\n[mcp_servers.linear]\nurl = "https://mcp.linear.app/mcp"\n' >>"$config" || exit 1
    step_record codex.linear || exit 1
fi

if step_done codex.linear && ! step_done codex.linear_login; then
    if confirm "Codex の Linear MCP にログインしますか？"; then
        codex mcp login linear --no-browser || exit 1
        step_record codex.linear_login || exit 1
    fi
fi

if ! command -v npx >/dev/null 2>&1; then
    confirm "Node.js をインストールしますか？" --exit-on-cancel
    ensure_npx || exit 1
fi
step_record node.npx || exit 1

setup_playwright() {
    if ! step_done codex.playwright && ! mcp_configured playwright; then
        confirm "Codex に Playwright MCP を追加しますか？" || return 0
    fi

    if step_done codex.playwright; then
        echo "Playwright MCP の設定は完了済みです。"
    elif mcp_configured playwright; then
        step_record codex.playwright || return 1
        echo "Playwright MCP の設定は既に存在します。"
    else
        mkdir -p "$(dirname "$config")" || return 1
        printf '\n[mcp_servers.playwright]\ncommand = "npx"\nargs = ["@playwright/mcp@latest"]\n' >>"$config" || return 1
        step_record codex.playwright || return 1
    fi

    if step_done chromium.install; then
        echo "Chromium はインストール済みです。"
    elif chromium_installed; then
        step_record chromium.install || return 1
        echo "Chromium はインストール済みです。"
    elif confirm "Chromium をインストールしますか？"; then
        install_chromium || return 1
        step_record chromium.install || return 1
    fi
}

setup_playwright || exit 1
