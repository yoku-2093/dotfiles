#!/bin/bash

chromium_installed() {
    local browser_dir
    case "${PLAYWRIGHT_BROWSERS_PATH:-}" in
    0) return 1 ;;
    "")
        case "$(uname -s)" in
        Darwin) browser_dir="$HOME/Library/Caches/ms-playwright" ;;
        Linux) browser_dir="${XDG_CACHE_HOME:-$HOME/.cache}/ms-playwright" ;;
        *) return 1 ;;
        esac
        ;;
    *) browser_dir="$PLAYWRIGHT_BROWSERS_PATH" ;;
    esac

    [[ -d $browser_dir ]] || return 1
    find "$browser_dir" -path '*/chromium-*/chrome-mac*/Chromium.app/Contents/MacOS/Chromium' -type f -perm -111 -print -quit | grep -q . ||
        find "$browser_dir" -path '*/chromium-*/chrome-linux*/chrome' -type f -perm -111 -print -quit | grep -q .
}

install_chromium() {
    npx -y playwright@latest install chromium
}
