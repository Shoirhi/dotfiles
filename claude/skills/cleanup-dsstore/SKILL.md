---
name: cleanup-dsstore
description: macOSの.DS_Storeファイルをシステム全体から削除し、今後の生成を抑制する。「DS_Store」「.DS_Store削除」「DS_Store消して」「DS_Storeクリーンアップ」「Finderのゴミ掃除」「macクリーンアップ」などと言われたら使う。gitignoreの設定だけ頼まれた場合も、.DS_Storeの全削除を提案すること。
---

# .DS_Store Cleanup

macOS全体から.DS_Storeファイルを削除し、再生成を可能な範囲で抑制するスキル。

## 背景

.DS_StoreはFinderがフォルダごとに自動生成するメタデータファイル。表示設定やアイコン配置などを保存している。gitリポジトリに混入すると差分ノイズになり、チーム開発で問題になる。ローカルディスク上の生成を完全に無効化するApple公式の方法は存在しないが、ネットワーク/USB上では抑制できる。

## 実行手順

### 1. 既存の.DS_Storeを全削除

デフォルトでシステム全体（`/`）から削除する。sudoが必要。

```bash
sudo find / -name ".DS_Store" -type f -delete 2>/dev/null
```

ユーザーがホームディレクトリだけで良いと言った場合:

```bash
find ~ -name ".DS_Store" -type f -delete
```

特定ディレクトリを指定された場合はそのパスを使う。

### 2. 再生成の抑制

ネットワークドライブとUSBドライブ上での生成を無効化する:

```bash
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
```

これらはApple公式サポートの設定。ローカルディスク上のFinderによる再生成は防げない旨をユーザーに伝える。

### 3. グローバルgitignore設定

既にグローバルgitignoreが設定されているか確認してから追加する:

```bash
# 現在の設定を確認
git config --global core.excludesfile
```

設定がなければ `~/.gitignore_global` を作成して設定:

```bash
git config --global core.excludesfile ~/.gitignore_global
```

ファイルに `.DS_Store` が既に含まれていなければ追記:

```bash
grep -qxF '.DS_Store' ~/.gitignore_global 2>/dev/null || echo '.DS_Store' >> ~/.gitignore_global
```

### 4. 完了報告

実行した内容をまとめてユーザーに報告する:

- 削除した対象範囲
- ネットワーク/USBドライブの抑制設定の有無
- gitignore設定の有無
- ローカルディスクではFinderがフォルダを開くたびに再生成される制限事項

## 注意事項

- `sudo find /` はシステム全体をスキャンするため数十秒かかることがある
- サンドボックス制限で `sudo find` が実行できない場合、ユーザーに手動実行を依頼する
- `defaults write` コマンドは再ログインまたは再起動後に反映される
