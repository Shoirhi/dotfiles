---
name: check-claude-update
description: Claude Codeの最新アップデート内容を確認し、自分の設定に取り入れるべき変更を提案するスキル。「アップデート確認」「changelog確認」「最新のClaude Code変更点」「新機能チェック」「Claude Codeの更新内容」「何が変わった？」「設定の見直し」などと言われたときに使う。Claude Codeのバージョンアップや新機能について聞かれたら、明示的にchangelogと言及していなくても積極的にこのスキルを使うこと。
---

# Check Claude Update

Claude Codeのchangelogから直近のアップデートを取得・要約し、ユーザーの現在の設定と照合して、取り入れるべき新機能や設定変更を提案する。

## ワークフロー

### Step 1: Changelogの取得

WebFetchツールで以下のURLからchangelogを取得する:

```
URL: https://code.claude.com/docs/en/changelog.md
プロンプト: Extract the 5 most recent version entries. For each version, list: version number, date, and all changes grouped by category (Features, Bug Fixes, Improvements, Breaking Changes). Include full details of each change.
```

### Step 2: アップデート要約の作成

取得したchangelogから直近5バージョンの内容を日本語で要約する。以下のフォーマットで出力:

```markdown
## Claude Code アップデート要約

### v{version} ({date})
**新機能**
- {機能の説明}

**改善**
- {改善の説明}

**バグ修正**
- {主要な修正のみ、重要度が高いものに絞る}

**破壊的変更** (あれば)
- {変更の説明}
```

要約のポイント:
- 新機能と改善は全て記載する（ユーザーにとって有用な情報なので）
- バグ修正は主要なもののみ（細かい内部修正は省略してよい）
- 破壊的変更は必ず全て記載する（見落とすとトラブルの原因になるため）

### Step 3: ユーザー設定の読み取り

以下のファイル・ディレクトリを読み取って、現在の設定状況を把握する:

1. `~/.claude/CLAUDE.md` — グローバル設定
2. `~/.claude/settings.json` — ツール許可、MCP設定など
3. `~/.claude/rules/` 配下のファイル — カスタムルール
4. `~/.claude/agents/` 配下のファイル — カスタムエージェント
5. `~/.claude/commands/` 配下のファイル — カスタムコマンド
6. `~/.claude/skills/` 配下のディレクトリ一覧 — インストール済みスキル

全てを並列で読み取ること（依存関係がないため）。

### Step 4: おすすめ設定の提案

changelogの新機能・改善とユーザーの現在の設定を照合し、取り入れるべき設定をおすすめ順に提案する。

以下のフォーマットで出力:

```markdown
## おすすめ設定の提案

### 1. {提案タイトル} (優先度: 高/中/低)
**関連バージョン**: v{version}
**概要**: {何ができるようになったか}
**現在の状態**: {ユーザーの設定にこれが含まれているか、関連する設定があるか}
**推奨アクション**: {具体的にどう設定すればよいか}
```

優先度の判断基準:
- **高**: セキュリティ改善、破壊的変更への対応、日常的なワークフローを大幅に効率化する機能
- **中**: 便利だが必須ではない新機能、既存設定の最適化
- **低**: ニッチな機能、特定の使い方でのみ有用な改善

提案が不要な場合（既に最新設定を取り入れている場合）は、その旨を伝えて終了する。

### Step 5: 出力

Step 2の要約とStep 4の提案をまとめて出力する。回答は全て日本語で行う。
