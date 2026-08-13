#!/usr/bin/env bash
# ラズパイでのみ実行される。install.sh から呼ばれる。
#
# 渡ってくる環境変数: DOTFILES_DIR / DOTFILES_TARGET / DOTFILES_ENV
#
# CLI ツールは common の aqua.yaml が入れる（64bit の Raspberry Pi OS 前提）。
# ここに書くのはこの環境固有のことだけ。
set -eu
