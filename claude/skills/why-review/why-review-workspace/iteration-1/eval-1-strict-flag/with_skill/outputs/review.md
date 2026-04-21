## PR Review: #34 feat: --strict を追加、generate の silent failure を exit 1 に (v2.0.7-beta.2)

### 変更サマリー

beta.1 で修正された「Vite 環境で `@source` が silent に未挿入」タイプの regression を CI で検出可能にするため、`generate` / `setup` コマンドに `--strict` フラグを導入するPR。あわせてエラーメッセージの actionable 化も実施。

**変更されたファイルと役割:**

| ファイル | 役割 |
|---|---|
| `bin/sparkle-design.js` | CLI エントリポイント。`--strict` オプションのパースとヘルプ表示 |
| `lib/constants.js` | `TAILWIND_NOT_FOUND` を文字列から関数に変更し、パスと修正方法を含むメッセージを生成 |
| `lib/font-manager.js` | コアロジック。`updateGlobalsWithFonts` / `manageFontImports` の戻り値を `{ status, reason? }` に変更。`resolveGlobalsPath` で明示パス未発見を throw に昇格 |
| `lib/generate-css.js` | `generateCSS` に `options` パラメータを追加し、strict を `manageFontImports` に伝搬。戻り値に `globalsResult` を含める |
| `lib/setup.js` | `runGenerate` が strict を受け取り、`--skip-generate`/`--dry-run` との併用時に警告。strict 時のエラー再 throw |
| `test/setup.test.js` | 8 件の統合テストを追加（strict 成功/失敗、skip-generate との併用警告、globals-path typo 検出など） |
| `CHANGELOG.md` | `[2.0.7-beta.2]` セクション追加 |
| `package.json` / `package-lock.json` | バージョンバンプ |

**影響範囲:** `manageFontImports` と `updateGlobalsWithFonts` の戻り値が boolean から `{ status, reason? }` に変更されている。ただし PR description によると既存テストでこれらの boolean 戻り値に依存するものは無かったとのこと。

---

### レビューコメント

**[praise]** 全体設計

`--strict` の導入設計が堅実。既定では後方互換を完全に維持しつつ、CI では `--strict` を付けるだけで silent failure を検出できるようにするアプローチは、段階的にユーザーを移行させる上で理にかなっている。beta リリースの段階でこの仕組みを入れたのは、正式リリース前の regression 検出という意味で時期的にも適切。

---

**[praise]** 戻り値の三値化 (`skipped` / `updated` / `failed`)

`lib/font-manager.js` 全体

`updateGlobalsWithFonts` の戻り値を boolean から `{ status: 'skipped' | 'updated' | 'failed', reason? }` に変更した判断が良い。「作業不要でスキップ」と「作業対象だったが失敗」の区別がつくことで、呼び出し側が状態に応じた分岐を明確に記述でき、将来的に他の状態（例: `'partial'` など）を追加する際にも拡張しやすい。

---

**[question]** `lib/font-manager.js`: `manageFontImports` の `hasWork` 判定

```js
const hasWork =
  (sourcePackages \!== null && sourcePackages \!== undefined) || Boolean(customCssPath);
```

この判定には `fontImports` の存在が含まれていない。`fontImports` だけがある（`sourcePackages` と `customCssPath` が空）のケースでは、entry CSS が見つからなくても `hasWork === false` となり `skipped` 扱いになる。現在の仕様上は「フォントは SparkleHead に移行済みなので fontImports 単独での作業はない」という前提だと理解しているが、この前提が CHANGELOG 等に明示されていないため確認したい。この `hasWork` の判定基準が将来の変更で意図と乖離するリスクはないか。

---

**[concern]** `lib/font-manager.js:516-523`: globals.css 更新成功後の sparkle-design.css 書き込み失敗

```js
if (result.status === 'skipped') {
  return result;
}
if (result.status === 'failed') {
  return raiseOrReturn(result);
}

// 5. fonts が sparkle-design.css 側に残っていれば削除
...
fs.writeFileSync(sparkleDesignPath, cleanedSparkleContent, 'utf8');
```

globals.css の更新は `result.status === 'updated'` で成功しているが、その後の `sparkle-design.css` への `writeFileSync` が失敗した場合、外側の catch に落ちて `{ status: 'failed', reason: 'manage-error: ...' }` として返る。この時点で globals.css は既に書き換え済みのため、中途半端な状態が発生する。coderabbitai も同じ指摘をしている。

今回のスコープとしては致命的ではないが、`--strict` モードでは「globals.css は更新されたが sparkle-design.css の更新が失敗した」ことが throw で伝わり、ユーザーから見ると「何が成功して何が失敗したか」が不明瞭になる可能性がある。将来的に、この二つの書き込みの成功/失敗を個別に報告できるようにすることを推奨する。

---

**[praise]** `lib/font-manager.js`: 明示パスの typo を throw に昇格

`resolveGlobalsPath` で明示指定されたパスが存在しない場合に、従来の `console.warn` + `return null` から `throw` に昇格させた判断が正しい。明示指定は「そのパスを使いたい」という強い意図の表明なので、silent に fallback するのは設定ミスの発見を遅らせるだけ。`error.code = 'E_EXPLICIT_GLOBALS_PATH_NOT_FOUND'` でタグ付けして上流で識別できるようにしている点も、エラーハンドリングの設計として丁寧。

---

**[suggestion]** `lib/font-manager.js`: `raiseOrReturn` のエラーメッセージに `reason` が含まれない場合の考慮

```js
const raiseOrReturn = (result) => {
  if (strict && result.status === 'failed') {
    throw new Error(
      `globals.css の更新に失敗しました (${result.reason ?? 'unknown'})。--strict モードでは exit 1 で終了します。`
    );
  }
  return result;
};
```

`result.reason` が `undefined` の場合に `'unknown'` が表示されるが、ユーザーにとって `unknown` は actionable ではない。`updateGlobalsWithFonts` が必ず `reason` を返す現在の実装では問題ないが、将来的に `reason` なしで `{ status: 'failed' }` が返される経路が追加された場合に、デバッグが困難になる。`reason` が必須であることを型やバリデーションで保証するか、`unknown` の代わりにより具体的なフォールバックメッセージ（例: 詳細不明。`--verbose` を付けて再実行してください）を検討すると良い。

---

**[question]** `lib/setup.js`: `--strict` のスコープが generate ステージのみである理由

CHANGELOG には「`setup --strict` は generate ステージの失敗のみを検出対象にします（install / scaffold / guard 書き込みの失敗は従来どおり warn）」と記載されている。この設計判断の背景を知りたい。

CI で `setup --strict` を使う場合、install や scaffold の失敗もキャッチしたいケースは想定されないか。もし将来的に他ステージにも strict を適用する計画があるなら、`--strict=generate` のようなステージ指定型の API にしておくと、後方互換を壊さずに拡張できる。現時点で generate のみにスコープを絞った理由（例: install/scaffold は冪等で失敗しにくい、など）があれば PR description に追記すると意図が後から追いやすくなる。

---

**[praise]** テストの網羅性

`test/setup.test.js` に追加された 8 件のテストケースが、`--strict` の主要なシナリオを的確にカバーしている:
- entry CSS 欠落での exit non-0
- Tailwind import 欠落での exit non-0 + actionable メッセージ検証
- 正常系での exit 0
- デザインシステムパッケージ未インストール時の exit 0（skip は正常系）
- `setup --strict` 経由の伝搬
- `--skip-generate` との併用警告
- `sparkle.config.json` の `globals-path` typo
- CLI の `--globals-path` typo

特に「作業不要の skip は strict でも成功扱い」のテストは、false positive を防ぐ上で重要な境界条件であり、これを含めた判断が良い。

---

**[nit]** `lib/generate-css.js`: フォーマット変更の混在

このPRの本質は `--strict` フラグの導入だが、Prettier によると思われるフォーマット変更（`.filter(line =>` を `.filter((line) =>`、配列リテラルの改行整理など）が複数ファイルにわたって含まれている。機能変更と無関係なフォーマット修正は別コミットに分けると、差分のレビューが容易になり、git blame でも変更意図が追いやすくなる。

---

### 総評

- **全体的な印象:** 質の高いPR。問題の明確な定義（silent failure を CI で検出したい）から設計判断（後方互換を維持しつつ opt-in の strict モード）、実装（三値化された戻り値、エラーコードによるタグ付け）、テスト（8 件の統合テストで主要シナリオをカバー）まで一貫性がある。セルフレビューで発見した問題を追加コミットで修正しているプロセスも良い。
- **特に良かった点:**
  - `{ status, reason }` への三値化は、今回の `--strict` だけでなく将来の拡張にも対応できる設計。
  - `E_EXPLICIT_GLOBALS_PATH_NOT_FOUND` のエラーコードタグ付けにより、catch 側で「意図的に再 throw すべきエラー」を正確に識別できている。
  - `--strict` と `--skip-generate` の併用時に警告を出す配慮。CI の設定ミスを見過ごさない。
- **マージ前に確認・対応してほしい点:**
  - `[question]` の 2 点（`hasWork` の判定基準、`--strict` のスコープが generate のみである理由）について、意図の確認またはドキュメントへの追記を推奨。これらは実装の正しさではなく、設計判断の透明性に関する指摘であり、回答が得られればマージに問題はない。
