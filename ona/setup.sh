#!/usr/bin/env bash
# ona (Gitpod Flex) の使い捨て環境でのみ実行される。install.sh から呼ばれる。
#
# 渡ってくる環境変数: DOTFILES_DIR / DOTFILES_TARGET / DOTFILES_ENV
#
# CLI ツールは common の aqua.yaml が入れる。ここに書くのはこの環境固有のことだけ。
set -eu
