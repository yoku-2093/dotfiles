# dotfiles

環境を指定して適用する dotfiles。

```sh
git clone <this repo> ~/dotfiles
~/dotfiles/install.sh --env ona
```

- 何度実行してもよい（既に正しい symlink なら何もしない）
- 既存のファイルは上書きせず `~/.dotfiles-backup/<日時>/` に退避する
- macOS / Linux で動く。bash と coreutils だけで完結する

## 環境

`common` と、指定した1つの環境だけを適用する。後のものが前のものを上書きする。

| `--env` | 何 |
| --- | --- |
| `ona` | ona (Gitpod Flex) の使い捨て環境 |
| `macos-local` | 手元の Mac |
| `raspberrypi` | ラズパイ（64bit の Raspberry Pi OS） |

**OS もアーキテクチャも自動判定しない。** ona とラズパイはどちらも Linux で
`uname` では区別できないので、環境は明示する。`--env` でも環境変数でもよい。

```sh
./install.sh --env macos-local
DOTFILES_ENV=macos-local ./install.sh   # 同じ（--env が優先）
```

環境を指定しなければ `common` だけを置く。

アーキテクチャ別のディレクトリは無い。CLI ツールの OS / arch 差は
[aqua](https://aquaproj.github.io/) が吸収する。

環境を増やしたいときはトップレベルにディレクトリを作るだけでよい（`common` 以外の
ディレクトリが自動的に `--env` の候補になる）。

## 各環境の中身

どちらも任意。片方だけでもよい。

```
<env>/
├── home/      $HOME からの相対パスで置いたファイルが symlink される
└── setup.sh    install 時に実行される
```

現状:

```
common/
├── home/.tmux.conf                            -> ~/.tmux.conf
├── home/.config/aquaproj-aqua/aqua.yaml       -> 入れる CLI ツール一覧
├── home/.config/dotfiles/shellenv.sh          -> PATH と aqua の設定
├── lib.sh                                      setup.sh から使うヘルパー (pkg_install)
└── setup.sh                                    tpm と aqua を入れる
ona/setup.sh
macos-local/
├── home/.zshrc                                -> ~/.zshrc
└── setup.sh
raspberrypi/setup.sh
```

### home/

| 置く場所 | できる symlink |
| --- | --- |
| `common/home/.gitconfig` | `~/.gitconfig` |
| `raspberrypi/home/.config/nvim/init.lua` | `~/.config/nvim/init.lua` |

途中のディレクトリは自動で作る。ディレクトリ自体は symlink にせずファイル単位で
張るので、`~/.config` の他の中身には触らない。

同じパスを `common` と環境の両方が持つ場合は、環境側が勝つ。

### setup.sh

`DOTFILES_DIR` / `DOTFILES_TARGET` / `DOTFILES_ENV` が渡される。
失敗しても install 全体は止まらず、警告を出して次に進む。

## CLI ツール (aqua)

`common/home/.config/aquaproj-aqua/aqua.yaml` に書いたものが全環境に入る。
aqua が OS とアーキテクチャを見て適切なリリースバイナリを取ってくるので、
環境ごとに分ける必要はない。

```sh
aqua g -i <owner>/<repo>   # aqua.yaml に最新版を追記する
aqua up                    # バージョンを上げる
```

- `common/setup.sh` が aqua 本体（バージョンと sha256 を固定）を
  `~/.local/share/aquaproj-aqua` に入れ、`aqua install -a` を実行する
- PATH を通すのは `~/.config/dotfiles/shellenv.sh`。rc から一度 source する

  ```sh
  . "$HOME/.config/dotfiles/shellenv.sh"
  ```

  `macos-local/home/.zshrc` には入れてある。ona とラズパイの rc は
  dotfiles 側で持っていないので、自分で1行足す
- `DOTFILES_AQUA_ONLY_LINK=1` を付けると実体を落とさず link だけ張る（初回が速い。
  実体は最初にコマンドを叩いたときに落ちてくる）

### aqua に向かないもの

| もの | どうするか |
| --- | --- |
| `tmux` などの OS 側のパッケージ | `<env>/setup.sh` で `pkg_install` |
| リリースバイナリを出していないツール | 同上（例: `eza` は macOS 向けバイナリが無く、aqua だと cargo ビルドになる） |
| 32bit のラズパイ (armv7l) | ほぼバイナリが無いので `pkg_install` で apt から |

### pkg_install

OS のパッケージを入れるヘルパー。`common/lib.sh` を source して使う。

```bash
. "${DOTFILES_DIR}/common/lib.sh"
pkg_install tmux
```

| 検出 | 実行されるもの |
| --- | --- |
| `brew` | `brew install`（sudo なし） |
| `apt-get` | `apt-get update` を1回 → `apt-get install -y --no-install-recommends` |
| `dnf` | `dnf install -y` |
| `pacman` | `pacman -S --needed --noconfirm` |
| `apk` | `apk add --no-cache` |
| `zypper` | `zypper install -y` |

root でなければ `sudo` を付け、どちらも使えなければ警告して失敗する（`setup.sh` の
失敗は install 全体を止めない）。`DOTFILES_PKG_DRY_RUN=1` で実行せずコマンドだけ表示できる。

吸収できるのはコマンドの違いだけで、パッケージ名の違い（`fd-find` / `fd` など）は
吸収できない。そういう CLI ツールは aqua 側に寄せる。

## オプション

```
--env <name>        環境を指定する (省略すると common だけを置く)
--target <dir>      配置先を変える (default: $HOME)
--backup-dir <dir>  退避先を変える (default: <target>/.dotfiles-backup)
--skip-setup        setup.sh を実行せず symlink だけ張る
--dry-run           何もせず、やることだけ表示する
--list              適用される内容を表示して終了する
-h, --help          ヘルプ
```

同じ設定は環境変数でも渡せる（オプションが優先）:
`DOTFILES_ENV` / `DOTFILES_TARGET` / `DOTFILES_BACKUP_DIR` / `DOTFILES_SKIP_SETUP`

### 動作確認

`$HOME` を汚さずに試せる。

```sh
./install.sh --env ona --list
./install.sh --env ona --target "$(mktemp -d)" --dry-run
./install.sh --env ona --target "$(mktemp -d)" --skip-setup
```

## 含めないもの

秘匿情報（トークン・鍵・暗号化ファイル）は置かない。
特定のサービスやエディタ固有の設定処理も入れない。

## tmux

`common/home/.tmux.conf` は [tpm](https://github.com/tmux-plugins/tpm) 前提。
`common/setup.sh` が clone するので、tmux 起動後に `prefix + I` を押せばよい。
