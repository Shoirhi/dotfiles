# XDG Base Directory
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# Homebrew (eval を避けてシェル起動を高速化)
if [[ -d /opt/homebrew ]]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
elif [[ -d /usr/local/Homebrew ]]; then
  export HOMEBREW_PREFIX="/usr/local"
fi
if [[ -n "${HOMEBREW_PREFIX-}" ]]; then
  export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
  export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX"
  export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:$PATH"
  export MANPATH="$HOMEBREW_PREFIX/share/man${MANPATH+:$MANPATH}:"
  export INFOPATH="$HOMEBREW_PREFIX/share/info:${INFOPATH:-}"
fi

# History
HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=100000
SAVEHIST=100000
mkdir -p "$(dirname "$HISTFILE")"
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY APPEND_HISTORY INC_APPEND_HISTORY HIST_REDUCE_BLANKS

# Aliases
source "$HOME/.config/zsh/aliases.zsh"

# Vi mode
bindkey -v
export KEYTIMEOUT=20
bindkey -M viins 'jk' vi-cmd-mode

# Starship prompt (guard against double-sourcing to prevent zle-keymap-select recursion)
if [[ -z "${__starship_initialized-}" ]]; then
  local _starship_bin; _starship_bin="$(command -v starship 2>/dev/null)"
  local _starship_cache="${XDG_CACHE_HOME:-$HOME/.cache}/starship-init.zsh"
  if [[ -n "$_starship_bin" && ( ! -f "$_starship_cache" || "$_starship_bin" -nt "$_starship_cache" ) ]]; then
    mkdir -p "$(dirname "$_starship_cache")"
    starship init zsh > "$_starship_cache"
  fi
  [[ -f "$_starship_cache" ]] && source "$_starship_cache"
  unset _starship_bin _starship_cache
  __starship_initialized=1
fi

# Completion system (1日1回だけフル再構築、それ以外はキャッシュ利用)
autoload -Uz compinit
ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump"
if [[ "$ZSH_COMPDUMP"(N.mh+24) ]]; then
  compinit -d "$ZSH_COMPDUMP"
else
  compinit -C -d "$ZSH_COMPDUMP"
fi

# Television (fuzzy finder) — compdef を使うため compinit の後に読み込む
local _tv_bin; _tv_bin="$(command -v tv 2>/dev/null)"
local _tv_cache="${XDG_CACHE_HOME:-$HOME/.cache}/tv-init.zsh"
if [[ -n "$_tv_bin" && ( ! -f "$_tv_cache" || "$_tv_bin" -nt "$_tv_cache" ) ]]; then
  mkdir -p "$(dirname "$_tv_cache")"
  tv init zsh > "$_tv_cache"
fi
[[ -f "$_tv_cache" ]] && source "$_tv_cache"
unset _tv_bin _tv_cache

# Zoxide (smart cd)
local _zoxide_bin; _zoxide_bin="$(command -v zoxide 2>/dev/null)"
local _zoxide_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zoxide-init.zsh"
if [[ -n "$_zoxide_bin" && ( ! -f "$_zoxide_cache" || "$_zoxide_bin" -nt "$_zoxide_cache" ) ]]; then
  mkdir -p "$(dirname "$_zoxide_cache")"
  zoxide init zsh > "$_zoxide_cache"
fi
[[ -f "$_zoxide_cache" ]] && source "$_zoxide_cache"
unset _zoxide_bin _zoxide_cache

# zsh-autosuggestions / zsh-syntax-highlighting (Homebrew)
if [[ -n "${HOMEBREW_PREFIX-}" ]]; then
  local _as="$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  local _sh="$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  [[ -f "$_as" ]] && source "$_as"
  [[ -f "$_sh" ]] && source "$_sh"
  unset _as _sh
fi
