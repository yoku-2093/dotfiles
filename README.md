# Dotfiles with Age Encryption

Secure dotfiles repository using [age](https://github.com/FiloSottile/age) encryption for Gitpod/ONA workspaces.

## Overview

This repository encrypts sensitive configuration files and automatically restores them in Gitpod/ONA workspaces using encrypted storage and environment-based secrets.

**Encrypted files:**
- `.bashrc` - Shell configuration (includes API tokens)
- `.ssh/*` - SSH keys and configuration for GitHub
- `.gitconfig` - Git user configuration

## Required Environment Variables

### For Dotfiles Installation

| Variable | Description | Where to Set | Required |
|----------|-------------|--------------|----------|
| `AGE_SECRET_KEY` | Age encryption secret key for decrypting dotfiles | Gitpod/ONA Secrets | **Yes** |

### Application Environment Variables (in .bashrc)

These variables are encrypted within `.bashrc` and automatically restored:

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `ANTHROPIC_AUTH_TOKEN` | Authentication token for Claude Code/Anthropic API | `sk-...` |
| `ANTHROPIC_BEDROCK_BASE_URL` | Base URL for Bedrock API endpoint | `https://litellm.glaze.services/bedrock` |
| `CLAUDE_CODE_SKIP_BEDROCK_AUTH` | Skip Bedrock authentication | `1` |
| `CLAUDE_CODE_USE_BEDROCK` | Enable Bedrock for Claude Code | `1` |
| `ANTHROPIC_SMALL_FAST_MODEL` | Model ID for small/fast operations | `anthropic.claude-3-5-haiku-...` |
| `LANG` | System locale setting | `ja_JP.UTF-8` |

**Note:** You only need to configure `AGE_SECRET_KEY` in Gitpod Secrets. All other variables are stored encrypted in `.bashrc` and automatically loaded when the workspace starts.

## Prerequisites

- **age**: Modern encryption tool
  - Install: `mise install age` or `sudo apt install age`
  - Download: https://github.com/FiloSottile/age/releases
- **Gitpod/ONA account** with access to Secrets/Variables

## Initial Setup

### 1. Install age

```bash
# Using mise (recommended if available)
mise install age

# Or using system package manager
sudo apt install age

# Or download from GitHub releases
curl -LO https://github.com/FiloSottile/age/releases/latest/download/age-v1.2.1-linux-amd64.tar.gz
tar xzf age-v1.2.1-linux-amd64.tar.gz
sudo mv age/age age/age-keygen /usr/local/bin/
```

### 2. Clone or Create Dotfiles Repository

```bash
mkdir -p ~/dotfiles
cd ~/dotfiles

# If starting fresh, initialize git
git init
```

### 3. Encrypt Your Configuration Files

Run the encryption script to encrypt your current dotfiles:

```bash
./scripts/encrypt.sh
```

**Usage:**
```bash
./scripts/encrypt.sh [--source DIR]

# デフォルト: ホームディレクトリから暗号化
# ※ HOME を対象にする場合は確認プロンプトが出ます
./scripts/encrypt.sh

# 特定のディレクトリを指定
./scripts/encrypt.sh --source /path/to/dotfiles
./scripts/encrypt.sh -s ~/my-configs
```

This script will:
- Generate an age key pair (if not exists)
- Encrypt `.bashrc`, `.gitconfig`, and `.ssh/*`
- Display your **secret key** (save this securely!)
- Show instructions for Gitpod/ONA configuration

**IMPORTANT:** Copy the secret key displayed - you'll need it in the next step.

### 4. Configure Gitpod/ONA Secrets

#### For Gitpod:

1. Go to: https://gitpod.io/user/variables
2. Click **"New Variable"**
3. Configure:
   - **Name:** `AGE_SECRET_KEY`
   - **Value:** Paste the secret key from step 3
   - **Scope:** `*/dotfiles` (or your repository pattern)
4. Save

#### For ONA:

1. Go to your ONA settings → Secrets
2. Add new secret:
   - **Name:** `AGE_SECRET_KEY`
   - **Value:** Paste the secret key from step 3
   - **Scope:** Configure for your dotfiles repository
3. Save

### 5. Configure Dotfiles Repository in Gitpod/ONA

#### For Gitpod:

1. Go to: https://gitpod.io/user/preferences
2. Under **Dotfiles**:
   - **Repository:** Enter your dotfiles repository URL (e.g., `https://github.com/username/dotfiles`)
3. Save

#### For ONA:

1. Go to your ONA workspace settings
2. Configure dotfiles repository URL
3. Save

### 6. Commit and Push

```bash
git add .
git commit -m "Initial dotfiles setup with age encryption"
git remote add origin <your-repository-url>
git push -u origin main
```

**⚠️ Security Check:** Ensure `.age-key.txt` is in `.gitignore` and NOT committed!

```bash
# Verify the key file is NOT tracked
git status | grep -q "age-key" && echo "WARNING: Key file is tracked!" || echo "✓ Safe"
```

## How It Works

### Workspace Startup Flow

1. **Gitpod/ONA clones** your dotfiles repository to the workspace
2. **Automatically executes** `install.sh` (ONA/Gitpod standard)
3. **Reads `AGE_SECRET_KEY`** from environment variables (Gitpod Secrets)
4. **Decrypts files** using age:
   - `encrypted/bashrc.age` → `~/.bashrc`
   - `encrypted/ssh.tar.age` → `~/.ssh/*` (extracted with permissions)
   - `encrypted/gitconfig.age` → `~/.gitconfig`
5. **Sets proper permissions**:
   - `.ssh/` → 700
   - `.ssh/github` (private key) → 600
   - Other files → 644
6. **Backs up** existing files to `~/.dotfiles-backup-<timestamp>/`

### File Structure

```
/home/me/dotfiles/
├── .gitignore                  # Excludes .age-key.txt
├── README.md                   # This file
├── install.sh                  # Auto-executed by Gitpod/ONA
├── scripts/
│   └── encrypt.sh             # Encrypt current dotfiles
└── encrypted/
    ├── bashrc.age             # Encrypted .bashrc
    ├── ssh.tar.age            # Encrypted .ssh directory (tar archive)
    └── gitconfig.age          # Encrypted .gitconfig
```

## Updating Dotfiles

When you make changes to your configuration files in a workspace:

### 1. Modify Your Files

Edit your dotfiles as needed:
```bash
vim ~/.bashrc
vim ~/.gitconfig
# ... make changes to ~/.ssh/config, etc.
```

### 2. Re-encrypt

Run the encryption script again:
```bash
cd ~/dotfiles
./scripts/encrypt.sh              # デフォルト: ホームディレクトリ (~/)
# または特定のディレクトリを指定:
./scripts/encrypt.sh --source /path/to/source
```

This will update the encrypted files in `encrypted/` directory.

### 3. Commit and Push

```bash
git add encrypted/
git commit -m "Update dotfiles configuration"
git push
```

### 4. Test in New Workspace

Launch a new Gitpod/ONA workspace to verify the updated configuration loads correctly.

## Manual Testing

You can test the installation script locally:

```bash
# Export the secret key (for testing only)
export AGE_SECRET_KEY="<your-secret-key-here>"

# Run install script
./install.sh

# Verify files
ls -la ~/.bashrc ~/.gitconfig ~/.ssh/
```

## Troubleshooting

### "AGE_SECRET_KEY environment variable is not set"

**Cause:** The secret key is not configured in Gitpod/ONA Secrets.

**Solution:**
1. Verify the secret exists in Gitpod/ONA settings
2. Check the variable name is exactly `AGE_SECRET_KEY`
3. Ensure the scope includes your dotfiles repository
4. Restart the workspace

### "age is not installed"

**Cause:** age encryption tool is not available in the workspace.

**Solution:**
```bash
# Install age
mise install age
# Or
sudo apt install age
```

### SSH Authentication Fails

**Cause:** SSH key permissions may be incorrect.

**Solution:**
```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/github
chmod 644 ~/.ssh/config

# Test connection
ssh -T git@github.com
```

### Files Not Decrypting

**Cause:** Wrong secret key or corrupted encrypted files.

**Solution:**
1. Verify `AGE_SECRET_KEY` in Gitpod Secrets matches the key from `encrypt.sh`
2. Re-run `encrypt.sh` to regenerate encrypted files
3. Check file integrity: `ls -lh encrypted/`

### Backup Location

Existing files are backed up before overwriting:
```bash
# Backups are stored in
~/.dotfiles-backup-<timestamp>/
```

## Security Considerations

### ✅ Safe to Commit:
- `encrypted/*.age` - Encrypted files
- `install.sh` - Installation script
- `scripts/encrypt.sh` - Encryption script
- `README.md` - Documentation

### ⚠️ NEVER Commit:
- `.age-key.txt` - Secret key file (add to `.gitignore`)
- Unencrypted configuration files
- Any file containing secrets or tokens

### Best Practices:
1. **Keep `AGE_SECRET_KEY` secure** - Store only in Gitpod/ONA Secrets
2. **Rotate keys periodically** - Generate new keys and re-encrypt
3. **Review changes before committing** - Ensure no secrets leaked
4. **Use separate keys per environment** - Dev, staging, production
5. **Backup your key** - Store securely offline (password manager, etc.)

## Advanced Usage

### Multiple Encryption Keys

You can encrypt for multiple recipients (e.g., team members):

```bash
# Edit encrypt.sh to add multiple recipients
age --encrypt --recipient <key1> --recipient <key2> -o output.age input
```

### Custom Files

To encrypt additional files, edit `scripts/encrypt.sh` and add:

```bash
encrypt_file "${SOURCE_DIR}/.myconfig" "${ENCRYPTED_DIR}/myconfig.age" ".myconfig"
```

Then update `install.sh` to decrypt it:

```bash
decrypt_file \
    "${ENCRYPTED_DIR}/myconfig.age" \
    "${HOME}/.myconfig" \
    ".myconfig" \
    "644"
```

## References

- [age encryption](https://github.com/FiloSottile/age)
- [ONA Dotfiles Documentation](https://ona.com/docs/ona/configuration/dotfiles/overview)
- [Gitpod Environment Variables](https://www.gitpod.io/docs/configure/projects/environment-variables)

## License

This dotfiles configuration is personal and not licensed for distribution.

---

**Generated for secure dotfiles management with age encryption**
