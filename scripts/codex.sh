#!/bin/bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/lib/confirm.sh"
source "$script_dir/lib/chrome.sh"
source "$script_dir/lib/history.sh"
source "$script_dir/lib/node.sh"
set -o pipefail

config="$HOME/.codex/config.toml"
agents_source="$script_dir/../AGENTS.md"
agents_target="$HOME/.codex/AGENTS.md"

if step_confirm codex.install "Codex をインストールしますか？"; then
    if ! curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh; then
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

update_playwright_config() {
    local temporary
    mkdir -p "$(dirname "$config")" || return 1
    touch "$config" || return 1
    temporary=$(mktemp "${config}.XXXXXX") || return 1
    if ! awk '
        BEGIN { section = 0; found = 0; command = 0; args = 0; bad = 0 }
        /^[[:space:]]*\[/ {
            if (section && (!command || !args)) bad = 1
            header = $0
            gsub(/[\047\042]/, "", header)
            section = (header ~ /^[[:space:]]*\[[[:space:]]*mcp_servers[[:space:]]*\.[[:space:]]*playwright[[:space:]]*\][[:space:]]*(#.*)?$/)
            if (header ~ /^[[:space:]]*\[[[:space:]]*mcp_servers[[:space:]]*\]/) bad = 1
            if (section && ++found > 1) bad = 1
        }
        section && /^[[:space:]]*command[[:space:]]*=/ {
            if (++command > 1 || $0 !~ /^[[:space:]]*command[[:space:]]*=[[:space:]]*"npx"[[:space:]]*(#.*)?$/) bad = 1
        }
        section && /^[[:space:]]*args[[:space:]]*=/ {
            if (++args > 1 || $0 !~ /^[[:space:]]*args[[:space:]]*=[[:space:]]*\[[[:space:]]*"@playwright\/mcp@latest"([[:space:]]*,[[:space:]]*"--browser"[[:space:]]*,[[:space:]]*"chrome")?[[:space:]]*\][[:space:]]*(#.*)?$/) bad = 1
            sub(/\]/, ", \"--browser\", \"chrome\"]")
            sub(/, \"--browser\", \"chrome\", \"--browser\", \"chrome\"/, ", \"--browser\", \"chrome\"")
        }
        { print }
        END {
            if (section && (!command || !args)) bad = 1
            if (bad) exit 1
            if (!found) {
                print ""
                print "[mcp_servers.playwright]"
                print "command = \"npx\""
                print "args = [\"@playwright/mcp@latest\", \"--browser\", \"chrome\"]"
            }
        }
    ' "$config" > "$temporary"; then
        rm -f "$temporary"
        echo "既存の Playwright MCP 設定を安全に更新できません。config.toml を確認してください。" >&2
        return 1
    fi
    cat "$temporary" > "$config" || { rm -f "$temporary"; return 1; }
    rm -f "$temporary"
}

setup_playwright() {
    if step_confirm codex.playwright "Codex に Playwright MCP を追加しますか？"; then
        update_playwright_config || return 1
        step_record codex.playwright || return 1
    fi

    if ! step_done codex.playwright; then
        return 0
    fi

    if step_confirm chrome.install "Google Chrome をインストールしますか？"; then
        install_chrome || return 1
        step_record chrome.install || return 1
    fi
}

setup_playwright || exit 1
