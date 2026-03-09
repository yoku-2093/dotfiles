# dotfiles

最小の手順は用途ごとに分けます。

まず age をインストールします:

macOS:

```bash
brew install age
```

Linux:

```bash
sudo apt install age
```

最初に `AGE_SECRET_KEY` を設定します:

```bash
export AGE_SECRET_KEY=<あなたのキー>
```

暗号化（source/ から encrypted/ を更新）:

```bash
./scripts/encrypt.sh
```

復号（encrypted/ から target/ に展開）:

```bash
./scripts/decript.sh
```

このリポジトリは、source/ にある設定ファイルを [dotfiles.manifest](dotfiles.manifest) の内容に沿って暗号化し、target/ に復号して配置します。暗号化は source/ を、復号は target/ を使う前提で動きます。

フォルダを指定して暗号化する場合:

```bash
./scripts/encrypt.sh \
  --source <入力元ディレクトリ>
```

フォルダを指定して復号する場合:

```bash
./scripts/decript.sh \
  --output <出力先ディレクトリ>
```

manifest を差し替える場合:

```bash
./scripts/encrypt.sh \
  --source <入力元ディレクトリ> \
  --manifest <manifestファイル>

./scripts/decript.sh \
  --output <出力先ディレクトリ> \
  --manifest <manifestファイル>
```

普段の編集は、source/ 側のファイルを直してから再暗号化し、[encrypted](encrypted) の変更をコミットするだけです。流れは「編集 → 暗号化 → コミット」です。

追加は簡単で、[dotfiles.manifest](dotfiles.manifest) に1行足すだけです。ファイルは .zshrc のように書き、ディレクトリは .ssh/ のように末尾 / を付けます。追加後に暗号化を実行すると、定義どおりに [encrypted](encrypted) が更新されます。
