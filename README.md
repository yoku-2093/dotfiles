# dotfiles

環境に応じたレイヤーを重ねて適用する dotfiles。

```sh
git clone <this repo> ~/dotfiles
~/dotfiles/install.sh
```

- 何度実行してもよい（既に正しい symlink なら何もしない）
- 既存のファイルは上書きせず `~/.dotfiles-backup/<日時>/` に退避する
- macOS / Linux で動く。bash と coreutils だけで完結する

## レイヤー

実行環境から下記の順にレイヤーを決めて、汎用的なものから順に適用する。
ディレクトリが無いレイヤーは飛ばすので、必要になったときに作ればよい。

| レイヤー | 条件 |
| --- | --- |
| `common/` | 全環境 |
| `macos/` `linux/` | OS |
| `macos-arm64/` `linux-amd64/` `linux-arm64/` `linux-armhf/` | OS + アーキテクチャ |
| `raspberrypi/` | Raspberry Pi（デバイスツリーのモデル名で判定） |

Raspberry Pi はアーキテクチャだけでは判別できない（Apple Silicon や Graviton も
`arm64`）ため、`/proc/device-tree/model` を見て別レイヤーにしている。
「arm64 の Linux 全般」に効かせたいものは `linux-arm64/` に置く。

判定結果は `install.sh` の実行時に `layers:` として表示される。

## 各レイヤーの中身

どちらも任意。片方だけでもよい。

```
<layer>/
├── links/      $HOME からの相対パスで置いたファイルが symlink される
└── setup.sh    install 時に実行される
```

現状:

```
common/
├── links/.tmux.conf     -> ~/.tmux.conf
└── setup.sh             tpm (tmux plugin manager) を入れる
macos/
├── links/.zshrc         -> ~/.zshrc
└── setup.sh
linux/setup.sh
```

`.zshrc` は BSD 版の `ls` 前提の alias を含むため `macos/` に置いている。

### links/

| 置く場所 | できる symlink |
| --- | --- |
| `common/links/.gitconfig` | `~/.gitconfig` |
| `linux/links/.config/nvim/init.lua` | `~/.config/nvim/init.lua` |

途中のディレクトリは自動で作る。ディレクトリ自体は symlink にせずファイル単位で
張るので、`~/.config` の他の中身には触らない。

同じパスを複数のレイヤーが持つ場合は、後のレイヤー（より具体的な方）が勝つ。

### setup.sh

`DOTFILES_TARGET` / `DOTFILES_OS` / `DOTFILES_ARCH` が渡される。
失敗しても install 全体は止まらず、警告を出して次に進む。

## 動作確認

`$HOME` を汚さずに試せる。レイヤーの判定も上書きできる。

```sh
DOTFILES_TARGET=$(mktemp -d) DOTFILES_SKIP_SETUP=1 ./install.sh

# ラズパイ想定で確認する
DOTFILES_TARGET=$(mktemp -d) DOTFILES_LAYERS="common linux linux-arm64 raspberrypi" ./install.sh
```

| 環境変数 | 既定値 | 用途 |
| --- | --- | --- |
| `DOTFILES_TARGET` | `$HOME` | 配置先 |
| `DOTFILES_BACKUP_DIR` | `$DOTFILES_TARGET/.dotfiles-backup` | 退避先 |
| `DOTFILES_OS` | `uname -s` から判定 | `macos` / `linux` |
| `DOTFILES_ARCH` | `uname -m` から判定 | `amd64` / `arm64` / `armhf` |
| `DOTFILES_LAYERS` | 判定結果 | レイヤーの並びを直接指定する |
| `DOTFILES_SKIP_SETUP` | - | `1` なら symlink だけ張る |

## 含めないもの

秘匿情報（トークン・鍵・暗号化ファイル）は置かない。
特定のサービスやエディタ固有の設定処理も入れない。

## tmux

`common/links/.tmux.conf` は [tpm](https://github.com/tmux-plugins/tpm) 前提。
`common/setup.sh` が clone するので、tmux 起動後に `prefix + I` を押せばよい。
