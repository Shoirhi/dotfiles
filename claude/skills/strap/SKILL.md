---
name: strap
description: Strap ボードへの作図操作を行う。ボードの読み取り、図形・テキスト・付箋・コネクタの作成・更新・削除、ページ管理、エレメント検索、ノート段落操作など、Strap の全作図機能を実行する。Strap のセットアップ・使い方・ツール仕様・トラブルシューティング・接続先やバージョンの状況確認・Strap ウェブアプリの URL 案内にも対応する。Use when the user wants to create diagrams, read boards, manage pages, manipulate elements on Strap, or ask about Strap setup, tool specs, connection status, web app URLs, and troubleshooting.
allowed-tools: Bash(~/dotfiles/claude/skills/strap/strap *), Bash(echo * | ~/dotfiles/claude/skills/strap/strap), Bash(cat * | ~/dotfiles/claude/skills/strap/strap), Read(~/dotfiles/claude/skills/strap/*), mcp__strap__strap
compatibility: "Claude Code CLI / Claude Desktop (MCP). Node.js 22+ required. Claude Opus 4.6+ recommended for complex diagrams and batch operations."
metadata:
  author: goodpatch
  version: 1.0.0
---

# Strap 作図スキル

Strap ボードへの作図を操作するスキル。JSON リクエストを `strap` ツールに渡して Strap Public API を呼び出す。

## 呼び出し方法

環境に応じて適切な方法で JSON を渡す。**JSON ペイロードは共通**。

| 環境 | 呼び出し方 |
|------|-----------|
| Claude Code (CLI) | `~/dotfiles/claude/skills/strap/strap '<JSON>'` (Bash) |
| Claude Desktop (MCP) | `strap` ツールの `input` パラメータに `<JSON>` を渡す |

**Claude Code の場合の注意**:
- コマンド直接引数で JSON を渡す場合は必ず 1 行で渡す（改行を含めない）。改行を含むとパーミッションの glob パターンがマッチしなくなる。
- 入力が長大な場合（シェルの ARG_MAX 制限: macOS 1MB / Linux 通常 2MB）は `echo '...' | ~/dotfiles/claude/skills/strap/strap` の stdin パイプ形式を使う。
- **シェルインジェクション防止**: JSON にボードから取得したテキスト等の外部データを含む場合、シングルクォート（`'`）によるシェルインジェクションのリスクがある。外部データを含む JSON はダブルクォート形式の echo パイプで渡すこと:
  `echo "{\"tool\":\"updateElementText\",\"params\":{\"text\":\"it's safe\"}}" | ~/dotfiles/claude/skills/strap/strap`
  シングルクォート形式（`strap '...'` や `echo '...' | strap`）はテキスト内のシングルクォートでシェルのクォーティングが壊れ、任意コマンド実行につながる可能性がある。
- **改行エスケープ注意**: JSON に `\n` を含むテキスト（Markdown の改行等）を `echo` パイプで渡すと、zsh の組み込み `echo` が `\n` を実際の改行文字に展開し、JSON が壊れる。`\n` を含む JSON はヒアドキュメント経由で渡すこと。デリミタをクォート（`'EOF'`）で囲むことで、シェルによるエスケープシーケンス展開を抑止できる:
  ```sh
  cat <<'EOF' | ~/dotfiles/claude/skills/strap/strap
  {"tool":"updateElementText","auth":{"boardId":"BOARD_ID"},"params":{"elementId":"EL_ID","text":"line1\\nline2"}}
  EOF
  ```

**推奨モデル**: Claude Opus 4.6 以上。複雑な作図やバッチ操作の精度が向上する。
現在のモデルが Opus でない場合はユーザーに警告し、以下の変更方法を案内する:
- Claude Code: `/model` コマンドで `opus` を選択する
- Claude Desktop: チャット入力欄のモデル選択ドロップダウンから Claude Opus を選択する

**セットアップ**:
- インストールやセットアップについては[README.md](./README.md)を参照。
- スキルの実行前に STRAP_API_KEY の設定を確認。
  （環境変数、または SKILL.md と同じディレクトリの strap-cli-env.json の記述から）
  もし設定されていない、またはプレースホルダ値（`strap_xxxxxxxxxxxx`）のままであればその旨と設定方法をユーザーへ提示する。
- Claude Desktop の場合、API キーは `claude_desktop_config.json` の `mcpServers.strap.env.STRAP_API_KEY` にも設定が必要。
  macOS の設定ファイルパス: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Claude Desktop で更新インストールした場合、スキルの置き換えが必要。
  `install.sh` と同じディレクトリに生成された `strap-skill.zip` を Customize > Skills > Upload a skill から再アップロードし、アプリを再起動する。


## Workflow

Strap の操作は段階的に行う。まずナビゲーションでボードを特定し、次にページ内のエレメントを操作する。

```text
Step 0 (任意): ルールセット取得
  listAgentRuleSets (auth: { spaceId }) → 利用可能なルールセット一覧
  getAgentRuleSet (auth: { spaceId }, params: { agentRuleSetId }) → ルールテキスト取得
  → 以降の作図操作でルール内容を優先的に考慮する

Step 1: ボード特定
  listSpaces → listBoards or searchBoardsByName → boardId を取得

Step 2: ページ特定
  readPages (auth: { boardId }) → pageId を取得

Step 3: エレメント操作
  createShape, createText, createConnector, ... (auth: { boardId })
```

### ワークスペーススコープ (auth 不要)

```json
{"tool":"listSpaces","params":{}}
{"tool":"getRecentlyUpdatedBoards","params":{}}
```

### スペーススコープ (spaceId 必要)

```json
{"tool":"listBoards","auth":{"spaceId":"SPACE_ID"},"params":{}}
```

### ボードスコープ (boardId 必要)

```json
{"tool":"readPages","auth":{"boardId":"BOARD_ID"},"params":{}}
{"tool":"createShape","auth":{"boardId":"BOARD_ID"},"params":{"pageId":"PAGE_ID","shapeType":"rectangle","x":100,"y":100,"width":200,"height":100}}
```

## Spaces & Pages の知識

### General スペース
- General スペースはどのスペースにも属さないボードの格納場所である
- spaceId には予約語 `"general"` を使用する
- listSpaces のレスポンスに `{ spaceId: "general", name: "General", accessType: "open" }` として含まれる
- ユーザーが「General スペース」や「スペースなし」と言った場合は `spaceId: "general"` を使う

### デフォルトページ（General ページ）
- ボード作成時にデフォルトページが自動生成される
- readPages のレスポンスで `isDefault: true` のページがデフォルトページである
- ユーザーが「デフォルトページ」や「最初のページ」と言った場合は `isDefault: true` のページを使う
- ページを指定せずにエレメント操作したい場合もデフォルトページを使う

## Input Formats

3 つの入力形式をサポートする。

### 単一オブジェクト (最もシンプル)

```json
{"tool":"readPages","auth":{"boardId":"abc"},"params":{}}
```

### 配列形式 (複数操作)

```json
[{"tool":"readPages","auth":{"boardId":"abc"},"params":{}},{"tool":"getElements","auth":{"boardId":"abc"},"params":{"pageId":"p1"}}]
```

### ラッパー形式 (共通 auth + エラー制御)

```json
{"auth":{"boardId":"abc"},"onError":"continue","requests":[{"tool":"readPages","params":{}},{"tool":"createShape","params":{"pageId":"p1","shapeType":"rectangle","x":0,"y":0,"width":200,"height":100}}]}
```

ラッパー形式が最も効率的。`auth` を共通化でき、`onError: "continue"` で途中エラーがあっても残りのリクエストを継続する。

## Scopes & Auth

| Scope | auth フィールド | 対象ツール |
|-------|----------------|-----------|
| workspace | 不要 (省略可) | listSpaces, getRecentlyUpdatedBoards, getRecentlyViewedBoards |
| space | `{ spaceId: "..." }` | listBoards, searchBoardsByName, listAgentRuleSets, getAgentRuleSet |
| board | `{ boardId: "..." }` | その他全ツール (readPages, create*, update*, delete*, get*, search*) |

## Output

成功時は JSON 配列が返る。

```json
[
  {"tool":"readPages","status":200,"result":[{"pageId":"p1","name":"Page 1"}]},
  {"tool":"createShape","status":200,"result":{"elementId":"el1","type":"shape"}}
]
```

エラー時はエラー情報が返る（CLI の場合は stderr + 非ゼロ exit code、MCP の場合は `isError: true`）。

### API エラーレスポンスの対処

エラーの詳細と対処方法は [references/troubleshooting.md](references/troubleshooting.md) を参照。

## Colors

カラー値は `#RRGGBB`（RGB）または `#RRGGBBAA`（RGBA、透明度付き）で指定する。任意のカラー値を自由に使用できる。

- `AA` 部分は透明度。`FF` = 不透明、`80` = 半透明、`00` = 完全透明
- 透明度は fillColor で主に使用される（付箋・画像・アイコンの半透明化）
- strokeColor / textColor でも RGBA は受け付けるが、透明度が視覚的に反映されるかは要素タイプによる
- 図形用と付箋用でカラーパレットが異なる

ユーザーのカラー指定が抽象的な場合（「赤」「青っぽい色」など）は、[references/colors.md](references/colors.md) の Strap 標準カラーパレットを参考値として使用する。

## Coordinate System

Strap ボードの座標系:
- 原点 (0, 0) は左上
- x は右方向に増加
- y は下方向に増加
- 単位はピクセル

### 推奨サイズ

| エレメント | 推奨 width | 推奨 height | 備考 |
|-----------|-----------|------------|------|
| Shape (rectangle) | 200 | 100 | 一般的なボックス |
| Shape (large) | 300 | 150 | タイトル付きボックス |
| Text | 200 | 40 | 1行テキスト |
| Sticky Note | 200 (固定) | 200 (固定) | サイズ指定不要 (x, y のみ) |

### 配置のコツ

- エレメント間の水平間隔: 40-60px
- エレメント間の垂直間隔: 40-60px
- フローチャートのノード間: 幅200 + 間隔50 = 250px ピッチ
- グリッド配置: x = col * 250, y = row * 160

### テキスト表示制約

以下のエレメントはテキストが描画領域を超えると省略記号（…）で切り詰められる。切り詰めが発生する場合、API レスポンスに `displayTruncation` 警告が返される。

- 図形（Rectangle, Circle, RoundRectangle, Rhombus, Triangle, Pill）
- 付箋（Sticky Note）

以下のエレメントは省略記号による切り詰めが発生しない。

- テキスト（Text）— テキスト内容がエレメントの高さを超えてもそのまま表示される
- コネクタ（Connector）— テキスト領域がテキスト内容に基づいて自動計算される

#### パディングと行高さ

| パラメータ | 値 |
|-----------|-----|
| 水平パディング | 32px（左右各16px） |
| 垂直パディング | 16px（上下各8px） |
| 行高さ | fontSize × 1.618 |

#### 表示可能行数の計算

```text
テキスト描画幅 = width - 32
テキスト描画高さ = height - 8
表示可能行数 ≈ floor(テキスト描画高さ / (fontSize × 1.618))
```

Triangle は高さの75%のみがテキスト領域になる。

#### 推奨 fontSize とエレメントサイズの組み合わせ

| fontSize | 行高さ (px) | height=100 での表示行数 | height=150 での表示行数 |
|----------|------------|----------------------|----------------------|
| 10 | 16 | 5 | 8 |
| 12 | 19 | 4 | 7 |
| 16 (default) | 26 | 3 | 5 |
| 24 | 39 | 2 | 3 |
| 32 | 52 | 1 | 2 |
| 48 | 78 | 1 | 1 |

#### displayTruncation 警告への対処

`displayTruncation` がレスポンスに含まれている場合、テキストが表示領域を超えている。以下のいずれかで対処する:

1. **エレメントの高さを拡張する**: `displayTruncation.suggestedHeight` の値で `updateElementSize` を呼ぶ
2. **fontSize を下げる**: `updateFontSize` で小さいフォントサイズに変更する
3. **テキストを短くする**: `updateElementText` でテキストを削減する

```json
// displayTruncation レスポンス例
{
  "displayTruncation": {
    "message": "Text exceeds the visible area. 2 of 5 lines are visible. Increase height to 218 to show all lines.",
    "visibleLines": 2,
    "totalLines": 5,
    "suggestedHeight": 218
  }
}
```

#### textTruncation と displayTruncation の違い

API レスポンスには2種類の切り詰め通知がある。

| フィールド | レベル | 発生条件 | データへの影響 |
|-----------|--------|---------|-------------|
| `textTruncation` | データレベル | テキストが 20,000文字 / 5,000行を超過 | テキストがサーバー側で切り詰められて保存される |
| `displayTruncation` | 表示レベル | テキストがエレメントの描画領域を超過 | テキストはそのまま保存されるが、フロントエンドで省略記号（…）表示になる |

### Z-Index（重なり順序）

エレメントの重なり順序は zIndex で制御する。値が大きいほど前面に表示される。

- `getElementIndexes` — ページ内エレメントの zIndex を一覧取得
- `updateElementIndex` — エレメントの zIndex を絶対値で設定

#### 背景候補エレメント（BackgroundCapable）と前景エレメント

エレメントは重なり順序において2つのカテゴリに分かれる:

| カテゴリ | エレメント種別 | 役割 |
|----------|--------------|------|
| 背景候補（BackgroundCapable） | 図形（Shape）、画像（Image） | 他のエレメントの背景として機能しうる |
| 前景 | テキスト、付箋、アイコン、コネクタ、罫線 | 背景候補エレメントより前面に表示されるべき |

**重要: 前景エレメントは背景候補エレメントより前面に配置すること。**
作成順序によっては、テキストや付箋が図形の後ろに入り込む場合がある。前景エレメントと背景候補エレメントを同じ領域に配置する場合は、作成後に zIndex を確認・調整すること。

**ワークフロー:**
1. 図形・テキスト等をバッチで作成する
2. `getElementIndexes` で全エレメントの zIndex を取得する
3. 前景エレメントが背景候補エレメントより後ろにある場合、`updateElementIndex` で前面に移動する

**注意**: 同じ zIndex 値を持つエレメント同士の描画順はボード再描画時に保証されない。再描画のたびに重なり順が前後する可能性がある。重なりが生じるエレメント同士には異なる zIndex 値を明示的に設定すること。

## 16:9 スライドレイアウト・ガイドライン (1920x1080)

プレゼンテーション用スライドを作図する際に基本として参照すべきレイアウト仕様がある。

### キャンバス

| パラメータ | 値 |
|-----------|-----|
| キャンバスサイズ | 1920 x 1080 px |
| アスペクト比 | 16:9 |
| グリッド原則 | すべての座標・サイズ・余白は 8 の倍数で設計する |

### マージン

| パラメータ | 値 |
|-----------|-----|
| 外マージン左右 | 96px |
| 外マージン上下 | 64px |
| コンテンツ領域幅 | 1728px (= 1920 - 96 × 2) |
| コンテンツ領域高さ | 952px (= 1080 - 64 × 2) |

### 4列グリッドシステム

| パラメータ | 値 |
|-----------|-----|
| 列数 | 4 |
| 1列幅 | 408px |
| ガター（列間余白） | 32px |
| 検証 | 408 × 4 + 32 × 3 = 1728px = コンテンツ領域幅 |

### 列スパン幅の計算

列スパン幅 = (1列幅 × スパン数) + (ガター × (スパン数 - 1))

| スパン数 | 幅 | 計算式 |
|---------|------|-------|
| 1列 | 408px | 408 |
| 2列 | 848px | 408 × 2 + 32 |
| 3列 | 1288px | 408 × 3 + 32 × 2 |
| 4列（全幅） | 1728px | 408 × 4 + 32 × 3 |

### フッター

| パラメータ | 値 |
|-----------|-----|
| フッター行高さ | 48px |
| 有効コンテンツ高さ | 約720〜760px（フッター・ヘッダー要素を除く目安） |

### 配置ルール

- すべての要素はコンテンツ領域（セーフゾーン: 外マージン内側）に収める
- 要素はグリッドの列端に揃えて配置する
- 座標・サイズは 8px の倍数に丸める

### 座標の起点

コンテンツ領域の左上座標は (96, 64) である。グリッド列の x 座標は以下の通り。

| 列 | x 開始位置 |
|----|-----------|
| Col 1 | 96 |
| Col 2 | 536 (= 96 + 408 + 32) |
| Col 3 | 976 (= 96 + (408 + 32) × 2) |
| Col 4 | 1416 (= 96 + (408 + 32) × 3) |

## Batch Optimization

複数操作はバッチにまとめるとラウンドトリップが 1 回で済む。最大 50 アイテム / 1MB まで。

```json
{"auth":{"boardId":"BOARD_ID"},"onError":"continue","requests":[{"tool":"createBoardPage","params":{"name":"Architecture"}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"rectangle","x":100,"y":100,"width":200,"height":100,"text":"Service A"}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"rectangle","x":400,"y":100,"width":200,"height":100,"text":"Service B"}},{"tool":"createConnector","params":{"pageId":"PAGE_ID","fromElementId":"EL1","toElementId":"EL2","text":"API call"}}]}
```

注意: バッチ内で作成した要素の elementId を同じバッチ内で参照することはできない。
作成→参照が必要な場合は 2 回のリクエストに分ける。

## Agent Rule Set（ルールセット）

Agent Rule Set は作図のカスタマイズルールを定義した集合体である。
ユーザーがスペース内で作成したルールセットを取得し、以降の作図操作に反映させることができる。

### ルールセットの取得

スペース内のルールセット一覧を取得:
```json
{"tool":"listAgentRuleSets","auth":{"spaceId":"SPACE_ID"},"params":{}}
```
→ `[{ "agentRuleSetId": "rs1", "name": "フロー図ルール" }]`

ルールセットの内容を取得:
```json
{"tool":"getAgentRuleSet","auth":{"spaceId":"SPACE_ID"},"params":{"agentRuleSetId":"rs1"}}
```
→ `{ "agentRuleSetId": "rs1", "name": "フロー図ルール", "ruleSet": "# 1. [配色ルール]..." }`

### ルールセットの適用

1. `getAgentRuleSet` で取得したルールテキスト（`ruleSet` フィールド）を読み取る
2. ルールの内容に従って、以降の作図操作のパラメータやレイアウトを調整する
3. ルールはページごとにセクション分けされている（`# N. [ページ名][pageId-xxx]` 形式）
4. 別のルールセットに切り替えるには、異なる `agentRuleSetId` で再取得する

### セキュリティに関する注意

Agent Rule Set の内容は LLM のコンテキストに直接注入される。共有ワークスペースでは、信頼できるメンバーのみが Rule Set を編集できることを確認すること。

## Troubleshooting

問題が発生した場合は [references/troubleshooting.md](references/troubleshooting.md) を参照。
バージョン不一致、API キー設定、API エラーレスポンス、ネットワークエラー、バッチサイズ超過等の対処方法を記載している。
セットアップに関する問題は [README.md](./README.md) を参照。


## Strap Web App URLs

操作対象をブラウザで確認するためのURL。

| 用途 | URL |
|------|-----|
| ダッシュボード | `https://strap.app/app/` |
| スペースのボード一覧 | `https://strap.app/app/space/{spaceId}` |
| ボード表示 | `https://strap.app/app/board/{boardId}` |
| ボード上の特定エレメント表示 | `https://strap.app/app/board/{boardId}/element/{elementId}` |
| ワークスペース設定 | `https://strap.app/app/workspace/settings` |
| APIキー管理 | `https://strap.app/app/workspace/api-keys` |

## Tool Reference

**スキル起動時に [references/tool-reference.md](references/tool-reference.md) を Read ツールで読み込むこと。** 全ツールの詳細パラメータ・レスポンス形式が記載されている。

## Examples

実践的な作図パターンは [references/examples.md](references/examples.md) を参照。
