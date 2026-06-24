#!/bin/bash
# Homebrew と Claude Code を定期的に自動更新するスクリプト。
# launchd から呼び出される想定。手動実行も可能。
set -uo pipefail

# launchd は最小限の環境変数で起動するため、PATH を明示的に設定する
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/.local/bin:$PATH"

LOG_DIR="$HOME/.local/state/dotfiles"
LOG_FILE="$LOG_DIR/auto-update.log"
MAX_LOG_BYTES=$((1024 * 1024)) # 1MB を超えたらローテート

mkdir -p "$LOG_DIR"

# ログが肥大化したら 1 世代だけ退避する
if [[ -f "$LOG_FILE" ]]; then
  log_size=$(wc -c <"$LOG_FILE" 2>/dev/null || echo 0)
  if [[ "$log_size" -gt "$MAX_LOG_BYTES" ]]; then
    mv -f "$LOG_FILE" "$LOG_FILE.1"
  fi
fi

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >>"$LOG_FILE"
}

# 失敗したステップを記録する（最後の通知でまとめて報告）
FAILED_STEPS=()

# macOS の通知センターにメッセージを表示する
notify() {
  local title="$1"
  local message="$2"
  osascript -e "display notification \"$message\" with title \"$title\"" >/dev/null 2>&1 || true
}

# コマンドを実行し、成否をログに残す（失敗しても処理は継続）
run_step() {
  local desc="$1"
  shift
  log "START: $desc"
  if "$@" >>"$LOG_FILE" 2>&1; then
    log "OK:    $desc"
  else
    log "FAIL:  $desc (exit $?)"
    FAILED_STEPS+=("$desc")
  fi
}

log "===== auto-update start ====="

# Homebrew
if command -v brew >/dev/null 2>&1; then
  run_step "brew update" brew update
  run_step "brew upgrade" brew upgrade
  run_step "brew cleanup" brew cleanup
else
  log "SKIP:  brew not found"
fi

# Claude Code
if command -v claude >/dev/null 2>&1; then
  run_step "claude update" claude update
else
  log "SKIP:  claude not found"
fi

log "===== auto-update done ====="

# 結果を通知センターに表示
if [[ ${#FAILED_STEPS[@]} -eq 0 ]]; then
  notify "アップデート完了" "Homebrew と Claude Code を最新にしました"
else
  notify "アップデートに失敗" "${FAILED_STEPS[*]} でエラーが発生しました。ログをご確認ください"
fi
