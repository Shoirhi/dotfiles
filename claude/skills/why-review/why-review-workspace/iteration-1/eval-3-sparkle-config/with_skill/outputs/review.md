## PR Review: #254 feat: change-sparkle-config skill 追加 (雰囲気を言葉で伝えて sparkle.config.json を書き換え)

### 変更サマリー

本PRは、導入済みの sparkle-design プロジェクトにおいて、ユーザーが「ポップにしたい」「ビジネスライクに」などの自然言語で雰囲気を伝えると、`sparkle.config.json` の4キー（`primary` / `font-pro` / `font-mono` / `radius`）を書き換えて `sparkle-design-cli generate` まで実行する Claude スキルを追加するもの。

**変更ファイル:**

- `.claude/skills/change-sparkle-config/SKILL.md`（新規追加 +130行）: スキル本体。9ステップの実行手順、許可リスト、雰囲気マッピングの代表例3パターンを定義
- `.claude/skills/change-sparkle-config/references/vibe-mapping.md`（新規追加 +110行）: 8パターンの詳細な雰囲気マッピング（選定理由・発動語彙付き）
- `.claude/skills/setup-sparkle-design/SKILL.md`（修正 +8/-10行）: description からテーマカスタマイズ系トリガーを削除し、初期セットアップ専用に限定

**影響範囲:** Claude スキルの定義ファイルのみの変更であり、アプリケーションコードへの影響はない。既存の `setup-sparkle-design` スキルの発動条件が変わるため、ユーザーの利用体験に影響する。

---

### レビューコメント

**[praise]** SKILL.md 全体

スキルの責務分離が明快で、setup（未導入向け）と change（導入済み向け）の境界が非常に分かりやすく設計されている。PR description にも「setup は未導入向け / change は導入済み向けで役割を分離」と明記されており、この判断は正しい。同一スキルに詰め込まず、単一責任原則をスキル設計にも適用している点はチームの参考になる。

---

**[praise]** SKILL.md:51-56（書き込み前バリデーション）

許可リストとの照合を「書き込み直前」に独立ステップとして設けている点が堅実。ステップ3のマッピングだけでは保証にならないという認識を明文化し、「このチェックをスキップしない」と断言しているのは、AI アシスタントへの指示として防御的で良い設計。

---

**[praise]** SKILL.md:57-65（最小差分書き換え + extend 保護）

`extend.*` や未知のトップレベルキーを保護し、4キーのみを書き換えるという制約は、既存プロジェクトの設定を壊さないために極めて重要。generate 後の exit code と mtime の検証、失敗時のロールバック方針まで含めて、安全性への配慮が行き届いている。

---

**[question]** SKILL.md:7-15（description / トリガー設計）

description に日本語・英語の両方で大量のトリガーワードが列挙されているが、これらのトリガーの優先度や衝突解決はどのように検証されたか？ 例えば「sparkle.config.json を書き換えて」は setup 側の旧トリガーから移動した形だが、ユーザーが「sparkle.config.json を作って」のように微妙に異なる表現をした場合、setup と change のどちらが発動するかの境界は十分に検証済みか？ PR description の Test plan に「setup-sparkle-design と change-sparkle-config が別文脈で正しく発動するか確認」とあるが、マージ前ではなくマージ後のテスト項目になっている点が気になる。

---

**[concern]** SKILL.md:40-41（JSONC 検出と JSON.parse の順序）

ステップ2で「`JSON.parse` で読み」と記述されたあと、同じステップ内で「JSONC（コメント付き）の場合は中断」とある。しかし、`JSON.parse` はコメントを含む JSONC を渡すとパースエラーになる。つまり、現在の手順記述では JSONC 検出よりも `JSON.parse` が先に実行される読み方になり、コメント付き config に対して意図した「中断してユーザーに判断を仰ぐ」ではなく、パースエラーという形で失敗する可能性がある。

手順の記述順序として、まずファイルを文字列として読み取り、コメントトークン（`//` や `/*`）の有無をチェックし、コメントがなければ `JSON.parse` に進む、という流れを明示した方が、AI アシスタントが正しく実装しやすい。CodeRabbit のレビューでも同様の指摘がされている。

---

**[question]** SKILL.md:62（generate 実行後の mtime 検証）

`src/app/sparkle-design.css` と `src/app/SparkleHead.tsx` の mtime を検証するとあるが、「（または config で指定した出力先）」という但し書きがある。config で出力先がカスタマイズされている場合、AI アシスタントはどのようにして正しい出力先を特定するのか？ `sparkle.config.json` の中に出力先の設定キーがあるならそれを読む手順を明示すべきだし、ない場合はデフォルトパスのみの検証で十分かを判断したい。この曖昧さは、AI アシスタントが「mtime 検証をスキップしても良い」と解釈するリスクがある。

---

**[suggestion]** references/vibe-mapping.md 全体（許可リストの二重管理）

SKILL.md と vibe-mapping.md の両方に許可リストが記載されており、「SKILL.md の許可リストと同一」「reference 単独参照でも自己完結できるよう再掲する」と説明されている。意図は理解できるが、将来フォントや色が追加された際に片方だけ更新されるリスクがある。PR description で「references に許可リスト転記で自己完結性向上」と判断した理由は分かるが、このトレードオフ（自己完結性 vs 同期コスト）は意識的に受け入れた判断という理解で合っているか？ もし可能であれば、どちらか一方を Single Source of Truth とし、他方は参照リンクのみにする方が保守性は高い。

---

**[nit]** SKILL.md:62

「`src/app/SparkleHead.tsx`」というパスがハードコードされているが、プロジェクトによっては `src/` 配下の構成が異なる可能性がある。ステップ9でも `<SparkleHead />` の設置確認を行う記述があるため、出力パスはステップ2で config から読み取った値を使う形に統一すると、より汎用的になる。

---

**[suggestion]** setup-sparkle-design/SKILL.md の変更差分

setup 側から削除されたトリガー（「テーマをカスタマイズしたい」「プライマリカラーを変えたい」「sparkle.config.json への言及」）について、change-sparkle-config 側の description には対応するトリガーが含まれているか再確認したい。「sparkle.config.json への言及」は change 側に「sparkle.config.json を書き換えて」として含まれているが、「sparkle.config.json」単体への言及（例: 「sparkle.config.json ってどこにある？」）は setup でも change でもカバーされなくなる。質問系のトリガーがどちらにも引っかからないケースについて、意図的に除外したのであれば問題ないが、確認しておきたい。

---

### 総評

- **全体的な印象:** 非常に丁寧に設計・文書化されたスキル追加PR。9ステップの手順が明確で、許可リストによる安全性の担保、extend 保護、generate 後の検証まで網羅的にカバーされている。Self-review で skill-reviewer の指摘を全件反映済みという点も、品質への意識が高い。
- **特に良かった点:** setup と change の責務分離の判断、「主案1本のみ」というUX方針（意思決定コストへの配慮）、許可リストを Figma プラグインと同集合に揃えるという Figma / CLI 間の一貫性への配慮。これらはビジネス文脈（デザイナーとエンジニアの協業）を正しく理解した上での設計判断と言える。
- **マージ前に確認・対応してほしい点:**
  1. JSONC 検出と `JSON.parse` の順序の明確化（concern）。AI アシスタントが正しい順序で実装できるよう、手順の記述を修正することを推奨。
  2. setup と change のトリガー境界テストを、マージ後ではなくマージ前に少なくとも1回は実施しておくことを推奨（Test plan の項目の前倒し）。
