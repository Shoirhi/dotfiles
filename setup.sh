#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"

# シンボリックリンクを作成（既に正しいリンクなら何もしない）
# ファイル・ディレクトリ両対応
link_file() {
  local src="$1"
  local dest="$2"
  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    echo "Already linked: $dest"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  ln -sfn "$src" "$dest"
  echo "Linked: $dest -> $src"
}

# Homebrewインストール
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "Homebrew is already installed."
fi

# Apple Silicon対応: HomebrewのPATH設定
if [[ -f /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Brewfileでパッケージインストール（インストール済みはスキップ、アップグレードしない）
# 一部のcaskがインストールエラーになっても他のパッケージは継続する
echo "Installing packages from Brewfile..."
if ! brew bundle --file="$DOTFILES_DIR/Brewfile" --no-upgrade --no-lock 2>&1; then
  echo "Warning: Some packages failed to install (see above). Continuing..."
fi
echo "Done."

# Claude Codeインストール
if ! command -v claude &>/dev/null; then
  echo "Installing Claude Code..."
  npm install -g @anthropic-ai/claude-code
else
  echo "Claude Code is already installed."
fi

# Playwrightインストール
if ! npx playwright --version &>/dev/null 2>&1; then
  echo "Installing Playwright..."
  npm install -g playwright
  npx playwright install --with-deps chromium
else
  echo "Playwright is already installed."
fi

# macOS設定
echo "Applying macOS settings..."
bash "$DOTFILES_DIR/macos.sh"
echo "Done."

# Git設定
link_file "$DOTFILES_DIR/git/config" "$HOME/.config/git/config"
link_file "$DOTFILES_DIR/git/ignore" "$HOME/.config/git/ignore"

# Ghostty設定
link_file "$DOTFILES_DIR/ghostty/config" "$HOME/.config/ghostty/config"

# Ghosttyテーマインストール（Catppuccin）
GHOSTTY_THEMES_DIR="$HOME/.config/ghostty/themes"
if [[ ! -f "$GHOSTTY_THEMES_DIR/catppuccin-frappe" ]]; then
  echo "Installing Catppuccin theme for Ghostty..."
  mkdir -p "$GHOSTTY_THEMES_DIR"
  TMPDIR_CATPPUCCIN="$(mktemp -d)"
  git clone --depth 1 https://github.com/catppuccin/ghostty.git "$TMPDIR_CATPPUCCIN"
  for f in "$TMPDIR_CATPPUCCIN/themes/"*.conf; do
    cp "$f" "$GHOSTTY_THEMES_DIR/$(basename "${f%.conf}")"
  done
  rm -rf "$TMPDIR_CATPPUCCIN"
else
  echo "Catppuccin theme for Ghostty is already installed."
fi

# Neovim設定（ディレクトリごとリンク）
link_file "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

# Zed設定
link_file "$DOTFILES_DIR/zed/settings.json" "$HOME/.config/zed/settings.json"

# Starship設定
link_file "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"

# Zsh設定
link_file "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_DIR/zsh" "$HOME/.config/zsh"

# Claude Code設定
mkdir -p "$HOME/.claude"
link_file "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
link_file "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
link_file "$DOTFILES_DIR/claude/statusline.sh" "$HOME/.claude/statusline.sh"
link_file "$DOTFILES_DIR/claude/rules" "$HOME/.claude/rules"
link_file "$DOTFILES_DIR/claude/skills" "$HOME/.claude/skills"
link_file "$DOTFILES_DIR/claude/agents" "$HOME/.claude/agents"

echo "Setup complete!"
