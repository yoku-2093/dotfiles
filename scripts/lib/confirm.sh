#!/bin/bash

confirm() {
    local answer
    read -r -p "$1 [y/N] " answer
    case "$answer" in
    y | Y) return 0 ;;
    *)
        echo "キャンセルしました。"
        if [[ ${2:-} == --exit-on-cancel ]]; then
            exit 0
        fi
        return 1
        ;;
    esac
}
