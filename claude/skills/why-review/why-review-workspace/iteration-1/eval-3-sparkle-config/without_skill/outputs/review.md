# PR #254 コードレビュー

## PR 概要

**タイトル**: change-sparkle-config skill 追加 (雰囲気を言葉で伝えて sparkle.config.json を書き換え)
**著者**: touyou (Fujii Yosuke)
**ブランチ**: `feat/change-sparkle-config-skill` -> `main`

自然言語で「ポップにしたい」「ビジネスライクに」等の雰囲気を伝えると、`sparkle.config.json` の primary / font-pro / font-mono / radius を書き換えて `sparkle-design-cli generate` まで実行する Claude 共有スキルの追加。既存の `setup-sparkle-design` スキルとの発動境界も整理。

---

## ビジネスコンテキストと「なぜ」

### なぜこのスキルが必要か

Sparkle Design はデザインシステムとして Figma プラグイン (Theme Settings) と CLI の両方でテーマを管理している。テーマ変更の操作には `sparkle.config.json` の書き換え -> CLI generate という手順が必要だが、非デザイナーや開発者にとって「どの値が何に対応するか」「許可されている値はどれか」を把握するのはコストが高い。

このスキルは、その認知コストを「言葉で雰囲気を伝える」だけに下げることで、テーマ変更のハードルを大幅に低減する。特に以下のビジネス価値がある:

1. **Figma とコードの一貫性維持**: 許可リストを Figma プラグインと同一にすることで、デザイナーが Figma で設定した値域と開発者が CLI で設定する値域がずれないことを保証している。これはデザインシステムにおいて非常に重要な設計判断。
2. **意思決定コストの低減**: 「主案1本のみ」というルールは、ユーザーに選択疲れを起こさせない UX 設計として適切。
3. **setup と change の責務分離**: 導入前/導入後で異なるスキルにすることで、それぞれの指示が肥大化せず、トリガーの誤発動も防げる。

### なぜこのタイミングか

PR description の Self-review セクションに「plugin-dev:skill-reviewer によるレビュー（Critical 3 / Major 4 / Minor 5 指摘）を全件反映済み」とある。既にスキルレビュアーによる品質チェックを経ており、熟度の高い状態でのレビュー依頼と読み取れる。

---

## 良い点

### 1. 9ステップの実行フローが堅牢

ステップ2の「現在値読み取り」でインデント幅やJSONCの検出まで行い、ステップ6で「書き込み前バリデーション」、ステップ8で「generate 実行と成果物検証」を独立ステップにしている。特に:

- JSONC（コメント付き JSON）検出時に中断する判断は、コメントを壊すリスクを確実に回避しており安全性が高い
- exit code だけでなく mtime 検証まで行う二重チェックも手堅い
- generate 失敗時の rollback / エスカレーション分岐も明確

### 2. 許可リストの設計

Figma プラグインと同一の値集合に揃えているのは、デザインシステムの一貫性を維持する上で本質的に正しい設計判断。font の pro/mono 用途制限を表形式で明示しているのもミスを防ぐ上で効果的。

### 3. Progressive Disclosure

SKILL.md に3パターンの即答用マッピング、`references/vibe-mapping.md` に8パターンの詳細マッピングという階層構造は、AI アシスタントのコンテキストウィンドウ効率の観点からも合理的。大半のリクエストは3パターンで対応でき、例外的なケースだけ reference を参照する。

### 4. setup スキルの description 修正

テーマカスタマイズ系のトリガーワード（「テーマをカスタマイズしたい」「プライマリカラーを変えたい」「sparkle.config.json への言及」）を削除し、代わりに change-sparkle-config への誘導を明記。この変更は差分が小さいが、両スキルの発動境界を明確にする上で不可欠。

---

## 指摘事項

### [重要] JSONC 検出と JSON.parse の順序

**ファイル**: `.claude/skills/change-sparkle-config/SKILL.md` (ステップ2)

ステップ2の記述では「`JSON.parse` で読み」と「JSONC（コメント付き）の場合は中断」が同一ステップに書かれているが、`JSON.parse` はコメント付き JSON を渡すとエラーを投げる。つまり、先に `JSON.parse` してしまうと JSONC かどうかを判断する前にクラッシュする可能性がある。

現在の記述:
> `sparkle.config.json` を **`JSON.parse` で読み**、現在の `primary` / `font-pro` / `font-mono` / `radius` / `extend.*` とそれ以外のユーザー独自キーを把握。
> (中略)
> JSONC（コメント付き）の場合はコメントを壊す可能性があるため、**中断してユーザーにマニュアル更新を促す**

**推奨**: ステップ2の手順を「(1) ファイルを文字列として読む -> (2) コメント文字列 (`//`, `/*`) の有無をチェック -> (3) コメントがあれば JSONC と判断して中断 -> (4) コメントがなければ JSON.parse」という順序に明記する。CodeRabbit も同様の指摘をしており、この点は修正すべき。

### [軽微] rollback 手順の明示性

**ファイル**: `.claude/skills/change-sparkle-config/SKILL.md` (ステップ8)

> 失敗した場合は書き換え前の `sparkle.config.json` に戻すか、エラー全文をユーザーに共有して手動対応を促す。

「書き換え前」の内容をどこから復元するかが暗黙的。ステップ2で読み取った内容を保持しておき、それを使って復元することを明記すると、AI アシスタントが確実に rollback を実行できる。例: 「ステップ2で読み取った元の内容を `sparkle.config.json` に書き戻す（rollback）」。

### [軽微] vibe-mapping.md のフォント制約の繰り返し表記

**ファイル**: `.claude/skills/change-sparkle-config/references/vibe-mapping.md`

許可リストの再掲は自己完結性のために意図的とのことだが、SKILL.md 側の許可リストと vibe-mapping.md 側の許可リストが将来的に乖離するリスクがある。どちらかを Single Source of Truth にし、もう一方は「SKILL.md の許可リストを参照すること」と明記するか、あるいは許可リストの更新時に両方を更新する旨の注意書きを加えると保守性が上がる。

現状は reference 冒頭に「SKILL.md の許可リストと同一」と注記があるので最低限のガードはされているが、例えば将来 primary に新色が追加された場合、片方だけ更新してもう片方を忘れるケースは十分ありうる。

### [確認] font-mono 列の `Inter` / `Lato` / `Open Sans` / `Montserrat`

**ファイル**: `.claude/skills/change-sparkle-config/SKILL.md` (許可リスト表)

これらは一般的にはプロポーショナルフォントであり、monospace フォントではない。font-mono に使用可能としている根拠は Sparkle Design 側の実装（CSS 変数として設定するだけで、実際の等幅レンダリングは保証しない等）にあると思われるが、レビュアーとして確認したい点。もし Sparkle Design の仕様として正しいのであれば問題ない。

### [提案] テストプランの具体化

PR description の Test plan に:
> マージ後、`pnpm sync:public-skills` で internal / docs に同期

とあるが、この同期が失敗した場合のフォールバック手順が記載されていない。同期先のリポジトリ（sparkle-design-internal / sparkle-design-docs）にも同じファイルを配置する必要があるなら、同期スクリプトの存在確認やドライラン結果をテストプランに含めると安心。

---

## 総評

全体として、よく設計された PR。特に以下の3つの設計判断が光る:

1. **Figma プラグインと同一の許可リストで Figma/CLI 間の一貫性を保証する**という判断は、デザインシステムの運用上極めて重要。値が自由すぎると Figma 側で再現できないテーマが生まれてしまうため、制約を設けること自体が正しい。
2. **主案1本のみ**という UX 方針は、AI アシスタントが無秩序に選択肢を並べがちな傾向への明確なカウンター。
3. **setup と change の分離**により、各スキルの指示が focused に保たれ、長期的な保守性も確保されている。

JSONC 検出順序の問題は実運用で問題になりうるため修正を推奨するが、それ以外は approve 可能な品質。
