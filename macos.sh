#!/bin/bash
set -euo pipefail

if [[ "$(uname)" != "Darwin" ]]; then
  echo "Error: This script is only for macOS." >&2
  exit 1
fi

# 変更があったアプリを追跡
CHANGED_APPS=()

# defaults write のラッパー: 値が既に設定済みならスキップ
safe_defaults() {
  local domain="$1"
  local key="$2"
  local type="$3"
  local value="$4"

  local current
  current=$(defaults read "$domain" "$key" 2>/dev/null) || current=""

  # bool値の正規化（defaultsは 1/0 で返す）
  local normalized_value="$value"
  if [[ "$type" == "-bool" ]]; then
    if [[ "$value" == "true" ]]; then
      normalized_value="1"
    else
      normalized_value="0"
    fi
  fi

  if [[ "$current" == "$normalized_value" ]]; then
    return
  fi

  defaults write "$domain" "$key" "$type" "$value"

  # 変更があったアプリを記録
  local app=""
  case "$domain" in
    com.apple.dock) app="Dock" ;;
    com.apple.finder) app="Finder" ;;
  esac
  if [[ -n "$app" && ! " ${CHANGED_APPS[*]+"${CHANGED_APPS[*]}"} " =~ " $app " ]]; then
    CHANGED_APPS+=("$app")
  fi
}

# === Dock ===
safe_defaults com.apple.dock autohide -bool true # Dock自動非表示
safe_defaults com.apple.dock tilesize -int 50 # Dockアイコンサイズ
safe_defaults com.apple.dock show-recents -bool false # 最近使ったアプリ非表示
safe_defaults com.apple.dock orientation -string "left" # Dockを左側に配置
safe_defaults com.apple.dock mru-spaces -bool false # Spacesを最近の使用順に並べ替えない
safe_defaults com.apple.dock expose-group-apps -bool true # Mission Controlでアプリをグループ化
safe_defaults com.apple.dock wvous-tl-corner -int 0 # 左上: 何もしない
safe_defaults com.apple.dock wvous-tr-corner -int 0 # 右上: 何もしない
safe_defaults com.apple.dock wvous-bl-corner -int 2 # 左下ホットコーナー: Mission Control
safe_defaults com.apple.dock wvous-br-corner -int 13 # 右下ホットコーナー: 画面ロック
safe_defaults com.apple.dock wvous-tl-modifier -int 0
safe_defaults com.apple.dock wvous-tr-modifier -int 0
safe_defaults com.apple.dock wvous-bl-modifier -int 0
safe_defaults com.apple.dock wvous-br-modifier -int 0

# === Finder ===
safe_defaults com.apple.finder ShowPathbar -bool true # パスバー表示
safe_defaults com.apple.finder ShowStatusBar -bool true # ステータスバー表示
safe_defaults com.apple.finder AppleShowAllFiles -bool true # 隠しファイル表示
safe_defaults com.apple.finder FXPreferredViewStyle -string "Nlsv" # リスト表示をデフォルトに
safe_defaults com.apple.finder FXEnableExtensionChangeWarning -bool false # 拡張子変更時の警告を無効化
safe_defaults com.apple.finder _FXSortFoldersFirst -bool true # フォルダを常に先頭に表示
safe_defaults com.apple.finder FXDefaultSearchScope -string "SCcf" # 検索時にカレントフォルダを対象
safe_defaults com.apple.finder NewWindowTarget -string "PfHm" # 新規ウィンドウでホームを開く
safe_defaults NSGlobalDomain AppleShowAllExtensions -bool true # 拡張子を常に表示

# === キーボード ===
safe_defaults NSGlobalDomain KeyRepeat -int 2 # キーリピート速度
safe_defaults NSGlobalDomain InitialKeyRepeat -int 15 # リピート開始までの時間
safe_defaults NSGlobalDomain ApplePressAndHoldEnabled -bool false # 長押しでリピート

# === トラックパッド ===
safe_defaults com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true # タップでクリック

# === 外観 ===
safe_defaults NSGlobalDomain AppleInterfaceStyle -string "Dark" # ダークモード
safe_defaults NSGlobalDomain AppleMenuBarVisibleInFullscreen -bool false # フルスクリーンでメニューバー非表示
safe_defaults NSGlobalDomain AppleMiniaturizeOnDoubleClick -bool false # タイトルバーダブルクリックで最小化しない
safe_defaults NSGlobalDomain AppleWindowTabbingMode -string "always" # 常にタブを使用

# === 入力補正 ===
safe_defaults NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false # 自動修正オフ
safe_defaults NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false # 自動大文字オフ
safe_defaults NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false # ピリオド自動挿入オフ
safe_defaults NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false # スマート引用符オフ
safe_defaults NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false # スマートダッシュオフ

# === スクリーンショット ===
mkdir -p ~/Pictures/Screenshots
safe_defaults com.apple.screencapture location -string "$HOME/Pictures/Screenshots" # 保存先を写真のScreenshotsに
safe_defaults com.apple.screencapture type -string "jpg" # JPG形式で保存
safe_defaults com.apple.screencapture style -string "selection" # デフォルトを範囲選択に

# === セキュリティ ===
safe_defaults com.apple.screensaver askForPassword -int 1 # スクリーンセーバー復帰時にパスワード要求
safe_defaults com.apple.screensaver askForPasswordDelay -int 0 # パスワード要求の遅延なし

# === ダイアログ ===
safe_defaults NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true # 保存ダイアログを常に展開
safe_defaults NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
safe_defaults NSGlobalDomain PMPrintingExpandedStateForPrint -bool true # 印刷ダイアログを常に展開
safe_defaults NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# === クラッシュレポーター ===
safe_defaults com.apple.CrashReporter DialogType -string "none" # クラッシュレポートダイアログ無効化

# === Time Machine ===
safe_defaults com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true # 新しいディスク接続時のバックアップ提案を無効化

# === Finder(追加) ===
safe_defaults com.apple.finder QuitMenuItem -bool true # Finderを終了可能にする
chflags nohidden ~/Library 2>/dev/null || echo "Warning: ~/Library の表示変更に失敗しました（sudo が必要な場合があります）"

# === ネットワーク ===
safe_defaults com.apple.NetworkBrowser BrowseAllInterfaces -bool true # AirDropを全インターフェースで有効化

# === アクティビティモニタ ===
safe_defaults com.apple.ActivityMonitor ShowCategory -int 0 # 全プロセス表示
safe_defaults com.apple.ActivityMonitor SortColumn -string "CPUUsage" # CPU使用率でソート
safe_defaults com.apple.ActivityMonitor SortDirection -int 0

# === その他 ===
safe_defaults NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false # デフォルト保存先をローカルに
safe_defaults com.apple.desktopservices DSDontWriteNetworkStores -bool true # .DS_Storeをネットワーク上に作らない
safe_defaults com.apple.desktopservices DSDontWriteUSBStores -bool true # USBドライブに.DS_Storeを作らない
safe_defaults com.apple.TextEdit RichText -int 0 # TextEditをプレーンテキストモードに

# 変更があったアプリのみ再起動
restart_if_changed() {
  local app="$1"
  if [[ " ${CHANGED_APPS[*]+"${CHANGED_APPS[*]}"} " =~ " $app " ]]; then
    killall "$app" 2>/dev/null || true
    echo "Restarted: $app"
  fi
}

restart_if_changed "Dock"
restart_if_changed "Finder"

echo "macOS settings applied!"