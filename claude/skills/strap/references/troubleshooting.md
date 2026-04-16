# Troubleshooting

## 接続先・バージョンの確認

サーバーに接続できない、または現在の接続先が不明な場合:

**方法 1: Claude Code から確認**

```bash
claude -p "/strap 現在の接続先は？"
```

スキル経由で strap コマンドを実行し、接続先やエラー情報を確認できる。

**方法 2: strap コマンドを直接実行**

```bash
~/dotfiles/claude/skills/strap/strap --version
```

バージョン情報と接続先 URL が表示される。バージョンが古い場合や接続先が意図と異なる場合は再インストールする。

## バージョン不一致エラー

strap CLI / MCP サーバーと Strap API はバージョンが一致している必要がある。
バージョン不一致時は API が 400 エラーを返す。チェックは CLI バージョン → スキーマバージョンの順で実行される。

**CLI バージョン不一致**

| エラーコード | 意味 | 対処 |
|---|---|---|
| `CLI_VERSION_INCOMPATIBLE` | クライアントと API の CLI バージョンが不一致 | 再インストールする |
| `MISSING_CLI_VERSION` | CLI バージョンヘッダーが送信されていない | 再インストールする |
| `INVALID_CLI_VERSION` | CLI バージョン形式が不正 | 再インストールする |

**スキーマバージョン不一致**

| エラーコード | 意味 | 対処 |
|---|---|---|
| `SCHEMA_VERSION_INCOMPATIBLE` | クライアントと API のスキーマバージョンが不一致 | 再インストールする |
| `MISSING_SCHEMA_VERSION` | スキーマバージョンヘッダーが送信されていない | 再インストールする |
| `INVALID_SCHEMA_VERSION` | スキーマバージョン形式が不正 | 再インストールする |

### バージョン確認コマンド

```bash
~/dotfiles/claude/skills/strap/strap --version
```

### 更新方法

更新手順は [README.md](../README.md) の「CLI の更新」節を参照。

## API エラーレスポンス

| error | message に含まれるキーワード | 原因 | ユーザーへの案内 |
|---|---|---|---|
| `FORBIDDEN` | `Public API is suspended for this workspace` | ワークスペース管理者が Public API の受信を停止している | ワークスペース管理者に Public API の受信再開を依頼する |
| `FORBIDDEN` | `API key is suspended` | ユーザーの APIキーが管理者により停止されている | ワークスペース管理者にキーの再開を依頼する |
| `FORBIDDEN` | `Workspace membership revoked` | ワークスペースから除外されている | ワークスペース管理者に確認する |
| `UNAUTHORIZED` | — | APIキーが無効または未設定 | 下記「STRAP_API_KEY の問題」を参照 |

**重要**: `suspended for this workspace` エラーはワークスペース単位の設定であり、APIキーの問題ではない。キーの再発行や変更では解決しない。ワークスペース管理者（admin ロール）が設定画面から受信を再開する必要がある。

## STRAP_API_KEY の問題

**症状**: `UNAUTHORIZED` エラー、またはプレースホルダ値エラー

**対処**:
1. `env | grep STRAP_API_KEY` で環境変数を確認する
2. プレースホルダ値（`strap_xxxx...`）が残っている場合は正しいキーに置換する
3. 環境変数が未設定の場合は `strap-cli-env.json` を確認する

API キーの設定方法の詳細は [README.md](../README.md) の「API キーの設定」節を参照。

## ネットワークエラー・タイムアウト

**症状**: exit code 2、接続拒否やタイムアウト

**対処**:
1. `~/dotfiles/claude/skills/strap/strap --version` で接続先を確認する
2. 接続先が意図と異なる場合は再インストールする
3. ネットワーク接続自体に問題がないか確認する

## バッチサイズ超過

**症状**: 50 アイテム超過または 1MB 超過でエラー

**対処**: リクエストを複数回に分割して実行する。

制約値:
- バッチアイテム数: 最大 50
- リクエストボディサイズ: 最大 1MB

## セットアップに関する問題

インストール、Node.js バージョン、パーミッション設定等のセットアップに関する問題は [README.md](../README.md) を参照。
