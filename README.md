# dotfiles

レイヤーを重ねて適用する dotfiles。

```sh
git clone <this repo> ~/dotfiles
~/dotfiles/install.sh
```

- 何度実行してもよい（既に正しい symlink なら何もしない）
- 既存のファイルは上書きせず `~/.dotfiles-backup/<日時>/` に退避する
- macOS / Linux で動く。bash と coreutils だけで完結する

## レイヤー

汎用的なものから順に適用し、後のレイヤーが前のレイヤーを上書きする。
ディレクトリが無いレイヤーは飛ばすので、必要になったときに作ればよい。

| レイヤー | 決まり方 |
| --- | --- |
| `common/` | 常に適用 |
| `linux/` `macos/` | `uname -s` |
| `linux/amd64/` `linux/arm64/` `macos/arm64/` | `uname -m` |
| `linux/raspberrypi/` など | **`--layer` で明示指定したときだけ** |

**自動で決まるのは `uname` から分かる OS とアーキテクチャだけ。** それ以外は自動判定
しない。ラズパイのような「特定環境向けの追加分」は明示的に指定する:

```sh
./install.sh --layer linux/raspberrypi
```

（ラズパイはアーキテクチャでも OS でも判別できない。arm64 は Apple Silicon や
Graviton も同じで、64bit Raspberry Pi OS は `/etc/os-release` に `ID=debian` を返す）

用途別に分けたいときも同じ仕組みで足せる（`--layer work` など）。

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
linux/
├── setup.sh
└── raspberrypi/setup.sh
```

`.zshrc` は BSD 版の `ls` 前提の alias を含むため `macos/` に置いている。

### links/

| 置く場所 | できる symlink |
| --- | --- |
| `common/links/.gitconfig` | `~/.gitconfig` |
| `linux/links/.config/nvim/init.lua` | `~/.config/nvim/init.lua` |

途中のディレクトリは自動で作る。ディレクトリ自体は symlink にせずファイル単位で
張るので、`~/.config` の他の中身には触らない。

同じパスを複数のレイヤーが持つ場合は、後のレイヤーが勝つ。

### setup.sh

`DOTFILES_TARGET` / `DOTFILES_OS` / `DOTFILES_ARCH` が渡される。
失敗しても install 全体は止まらず、警告を出して次に進む。

## オプション

```
--layer <name>      レイヤーを追加する（リポジトリ直下からの相対パス。複数回指定可）
--layers "<a b c>"  自動判定を使わずレイヤーの並びを直接指定する
--os <name>         OS の判定を上書きする (macos / linux)
--arch <name>       アーキテクチャの判定を上書きする (amd64 / arm64 / armhf)
--target <dir>      配置先を変える (default: $HOME)
--backup-dir <dir>  退避先を変える (default: <target>/.dotfiles-backup)
--skip-setup        setup.sh を実行せず symlink だけ張る
--dry-run           何もせず、やることだけ表示する
--list              適用されるレイヤーの状態を表示して終了する
-h, --help          ヘルプ
```

同じ設定は環境変数でも渡せる（オプションが優先）:
`DOTFILES_TARGET` / `DOTFILES_BACKUP_DIR` / `DOTFILES_OS` / `DOTFILES_ARCH` /
`DOTFILES_LAYERS` / `DOTFILES_SKIP_SETUP`

### 動作確認

`$HOME` を汚さずに試せる。

```sh
./install.sh --list                          # 何が適用されるか見る
./install.sh --target "$(mktemp -d)" --dry-run
./install.sh --target "$(mktemp -d)" --os macos --arch arm64 --skip-setup
```

## 含めないもの

秘匿情報（トークン・鍵・暗号化ファイル）は置かない。
特定のサービスやエディタ固有の設定処理も入れない。

## tmux

`common/links/.tmux.conf` は [tpm](https://github.com/tmux-plugins/tpm) 前提。
`common/setup.sh` が clone するので、tmux 起動後に `prefix + I` を押せばよい。
