# dotfiles

```bash
cd ~/dotfiles
bash setup.sh
```

## 自動アップデート

`setup.sh` を実行すると、Homebrew と Claude Code を毎日 12:00 に自動更新する
LaunchAgent (`com.shoirhi.dotfiles.autoupdate`) がインストールされる。

- 更新内容: `brew update` / `brew upgrade` / `brew cleanup` / `claude update`
- 実行時刻にスリープ・電源オフでも、次回起動・復帰時に一度だけ実行される
- ログ: `~/.local/state/dotfiles/auto-update.log`
- 完了時は macOS の通知センターに結果を表示（正常完了 / 失敗したステップ一覧）

### 手動実行・管理

```bash
# 手動で今すぐ更新
bash ~/dotfiles/scripts/auto-update.sh

# 即時実行（launchd経由で起動）
launchctl start com.shoirhi.dotfiles.autoupdate

# 登録状態の確認
launchctl list | grep autoupdate

# 一時停止 / 再開
launchctl unload ~/Library/LaunchAgents/com.shoirhi.dotfiles.autoupdate.plist
launchctl load   ~/Library/LaunchAgents/com.shoirhi.dotfiles.autoupdate.plist

# ログ確認
tail -f ~/.local/state/dotfiles/auto-update.log
```