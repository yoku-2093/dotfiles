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

if step_confirm codex.install "Codex をインストールしますか？"; then
    if ! curl -fsSL https://chatgpt.com/codex/install.sh | sh; then
        echo "Codex のインストールに失敗しました。" >&2
        exit 1
    fi
    codex --version || exit 1
    step_record codex.install || exit 1
fi

if step_confirm codex.agents "Codex の AGENTS.md に追記しますか？"; then
    mkdir -p "$(dirname "$agents_target")"
    cat "$agents_source" >>"$agents_target" || exit 1
    step_record codex.agents || exit 1
fi

if step_confirm codex.linear "Codex に Linear MCP を追加しますか？"; then
    mkdir -p "$(dirname "$config")"
    printf '\n[mcp_servers.linear]\nurl = "https://mcp.linear.app/mcp"\n' >>"$config" || exit 1
    step_record codex.linear || exit 1
fi

if step_done codex.linear; then
    if step_confirm codex.linear_login "Codex の Linear MCP にログインしますか？"; then
        codex mcp login linear --no-browser || exit 1
        step_record codex.linear_login || exit 1
    fi
fi

if step_confirm node.npx "Node.js をインストールしますか？"; then
    install_node || exit 1
    step_record node.npx || exit 1
fi
load_nvm_if_needed

setup_playwright() {
    if step_confirm codex.playwright "Codex に Playwright MCP を追加しますか？"; then
        mkdir -p "$(dirname "$config")" || return 1
        printf '\n[mcp_servers.playwright]\ncommand = "npx"\nargs = ["@playwright/mcp@latest"]\n' >>"$config" || return 1
        step_record codex.playwright || return 1
    fi

    if ! step_done codex.playwright; then
        return 0
    fi

    if step_confirm chromium.install "Chromium をインストールしますか？"; then
        install_chromium || return 1
        step_record chromium.install || return 1
    fi
}

setup_playwright || exit 1
