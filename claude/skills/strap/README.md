# Strap 作図スキル

本ディレクトリは Strap 作図用スキルである。Claude Code と Claude Desktop の両方で利用できる。

- **Claude Code** — strap CLI コマンド（Bash）経由で Strap Public API を呼び出す
- **Claude Desktop** — MCP サーバー経由で Strap Public API を呼び出す

どちらも JSON-in / JSON-out で同じペイロード形式を使用する。


## 前提事項

- Node.js バージョン 22 の事前インストールが必要
- 事前に Strap ウェブアプリケーションから API キー の発行が必要

### Node.js のインストール

Node.js がインストールされていない場合、公式サイトからインストールする。

1. https://nodejs.org/ にアクセスする
2. v22（LTS）をダウンロードする
3. ダウンロードしたインストーラーを実行する
4. インストール後、ターミナルでバージョンを確認する

```bash
node --version
# → v22.x.x であること
```

あるいはユーザー任意の方法（Homebrew、nvm、volta 等）でも構わない。


## Setup

### 1. strap CLI のインストール

strap コマンドはインストーラーでインストールできる。
strap コマンドのインストーラーは Strap アプリの API キー管理からダウンロードできる。
必要なものは skills/strap/ にすべて同梱されているので、インストーラーで一括配置できる。

```bash
# インストーラーをダウンロードし、その保存場所へディレクトリ移動する
cd ~/Downloads

# インストーラーを実行する
bash ./install.sh

# インストーラーの最後で設定ファイルに保存する API キーを尋ねられるので入力する
```

`install.sh` は以下をおこなう:

1. スキルファイル + strap コマンド + MCP サーバーを `~/dotfiles/claude/skills/strap/` へコピー
2. 以下のパーミッションを `~/.claude/settings.json` に追加（確認あり）
   - `Skill(strap)`
   - `Bash(~/dotfiles/claude/skills/strap/strap *)`
   - `Read(~/dotfiles/claude/skills/strap/*)`

   strap CLI はコマンド引数が毎回異なるため、パーミッションが未登録だと Claude Code が実行のたびに許可を求める。これを避けるために glob パターンで事前許可を登録する。

3. Claude Desktop がインストールされている場合、MCP サーバー設定を `claude_desktop_config.json` に追加（確認あり）
4. Claude Desktop 用のスキル zip（`strap-skill.zip`）を `install.sh` と同じディレクトリに生成

#### Claude Desktop を利用する場合の追加手順

`install.sh` の実行後、以下の手順が必要:

1. `install.sh` と同じディレクトリに生成された `strap-skill.zip` を Claude Desktop の **Customize > Skills > Upload a skill** からアップロードする
2. API キーを `claude_desktop_config.json` の `mcpServers.strap.env.STRAP_API_KEY` に設定する（`install.sh` の対話プロンプトで入力済みの場合は自動設定される）

   macOS の場合の設定ファイルパス: `~/Library/Application Support/Claude/claude_desktop_config.json`

   ```json
   {
     "mcpServers": {
       "strap": {
         "env": {
           "STRAP_API_KEY": "strap_xxxxxxxxxxxx"
         }
       }
     }
   }
   ```

3. Claude Desktop を再起動する（または Settings > Developer から MCP サーバーを再起動する）

セットアップ完了後、`strap-skill.zip` や `install.sh` (あれば) は削除して構わない。


### 2. API キーの設定

Strap の「ワークスペース設定 > API キー管理」から API キーを発行できる。

API キーはスキルディレクトリ（SKILL.md のあるディレクトリ）の設定ファイル strap-cli-env.json に設定できる。

```json
{
  "STRAP_API_KEY": "strap_xxxxxxxxxxxx"
}
```

ただしシェルの環境変数が設定済み（空文字列でない）の場合はそちらが優先される。

```bash
export STRAP_API_KEY=strap_xxxxxxxxxxxx
```

**注意**: シェルの環境変数にプレースホルダ値（`strap_xxxx...`）が残っていると、`strap-cli-env.json` に正しいキーを設定しても環境変数が優先されてエラーになる。プレースホルダエラーが出た場合は `env | grep STRAP_API_KEY` で環境変数を確認すること。

**セキュリティに関する注意**: `strap-cli-env.json` は API キーを含む機密ファイルである。パーミッションが `600`（所有者のみ読み書き可能）であることを確認すること。`install.sh` は自動的に設定するが、手動でコピーした場合は以下で修正できる。

```bash
chmod 600 ~/dotfiles/claude/skills/strap/strap-cli-env.json
```


### 3. 動作確認

```bash
~/dotfiles/claude/skills/strap/strap --version
# → @strap/cli x.x.x (schema x.x.x)
#    endpoint: https://asia-northeast1-xxx.cloudfunctions.net/v2-httpEvents-publicApi-cli/api/v1/cli
```

`--version` で現在の接続先エンドポイントも表示される。接続先が意図したものか確認できる。

strap コマンドの Exit Codes ($?) は次のとおり；

| コード | 意味                                                                       |
|--------|----------------------------------------------------------------------------|
|    0   | 全リクエスト成功                                                           |
|    1   | クライアントエラー（API キー未設定、バリデーションエラー、4xx レスポンス） |
|    2   | サーバーエラー（5xx レスポンス、ネットワークエラー）                       |

strap コマンドの制約事項は次のとおり；

- バッチアイテム数: 最大 50
- リクエストボディサイズ: 最大 1MB
- 空配列 `[]` は有効な入力（レスポンスも `[]`、exit 0）
- `onError`: `"abort"`（デフォルト）または `"continue"` を指定可能



## Claude Desktop での利用

`install.sh` が Claude Desktop の設定を自動で行う。手動設定が必要な場合は以下を参照。

### 1. MCP サーバー設定

`install.sh` は Claude Desktop の設定ファイルに MCP サーバーを自動登録する。
設定ファイルは Claude Desktop の **Settings → Developer → Edit Config** からも開ける。

設定ファイルのパス: `~/Library/Application Support/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "strap": {
      "command": "/absolute/path/to/node",
      "args": ["~/dotfiles/claude/skills/strap/strap-mcp"],
      "env": {
        "STRAP_API_KEY": "strap_xxxxxxxxxxxx"
      }
    }
  }
}
```

**注意**:
- `command` には `node` のフルパスが必要。Claude Desktop は GUI アプリのためシェルの PATH を継承しない。`which node` で確認できる。
- 設定変更後は Claude Desktop の再起動が必要。

### 2. スキルのアップロード

`install.sh` は Claude Desktop 用のスキル zip（`strap-skill.zip`）を `install.sh` と同じディレクトリに生成する。

1. Claude Desktop で **Customize → Skills → Upload a skill** を開く
2. `strap-skill.zip` をアップロードする

スキルをアップロードすると、Claude Desktop が SKILL.md の内容に従って MCP サーバー経由で Strap API を呼び出せるようになる。


## CLI の更新

strap CLI と Strap API のバージョンが不一致になると `CLI_VERSION_INCOMPATIBLE` または `SCHEMA_VERSION_INCOMPATIBLE` エラーが発生する。
この場合は CLI の更新が必要である。

### 更新手順

以下のいずれかの方法で最新の install.sh を取得し、実行する。

**方法 1: ダウンロードして実行**

Strap アプリの「ワークスペース設定 > API キー管理」画面からインストーラーをダウンロードしてターミナルで実行する。
あるいは以下のリンクから直接ダウンロードできる。

https://strap.app/statics/cli/install.sh

ダウンロードした場合は以下のように実行する。

```bash
cd ~/Downloads
bash ./install.sh
```

**方法 2: curl で直接取得**

```bash
bash <(curl -fsSL https://strap.app/statics/cli/install.sh)
```

**チェックサム検証（任意）**

ダウンロードした `install.sh` の整合性を確認したい場合:

```bash
curl -fsSL https://strap.app/statics/cli/install.sh.sha256 -o install.sh.sha256
shasum -a 256 -c install.sh.sha256
```

いずれの方法も既存のファイルを上書きする。API キーの設定（`strap-cli-env.json`）は保持される。

**重要**:
- **Claude Code**: 更新後は新しいセッションを開始すること。スキル定義（SKILL.md 等）はセッション開始時に読み込まれるため、現在のセッションには反映されない。
- **Claude Desktop**: 更新後は以下の手順が必要。
  1. `install.sh` と同じディレクトリに生成された `strap-skill.zip` を Customize > Skills > Upload a skill から再アップロードする
  2. アプリを再起動するか、Settings > Developer から MCP サーバーを再起動する

### 更新の確認

```bash
~/dotfiles/claude/skills/strap/strap --version
# → @strap/cli x.x.x (schema x.x.x)
```

バージョンが更新されていることを確認する。

