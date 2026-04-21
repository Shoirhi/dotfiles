# PR #34 コードレビュー

## PR 概要

`generate` / `setup` コマンドに `--strict` フラグを追加し、CI 環境で silent failure を exit 1 として検出可能にする変更。beta.1 で修正した「Vite 環境で `@source` が未挿入」の類の regression を CI で拾えるようにすることが目的。加えて、エラーメッセージを actionable に整理し、`--globals-path` の typo を即座に検出する仕組みも導入。

---

## 良い点

### 1. 問題の本質を的確に捉えた設計判断

silent failure が CI で検出できないという問題に対し、デフォルトの後方互換性を保ちつつ `--strict` でオプトインさせる設計は妥当。既存ユーザーのワークフローを壊さずに、CI パイプラインでの検出能力を向上させている。

### 2. 三値ステータスによる内部 API の改善

`updateGlobalsWithFonts` / `manageFontImports` の戻り値を `boolean` から `{ status: 'skipped' | 'updated' | 'failed', reason? }` に変更したのは良い改善。「作業不要でスキップ」と「作業対象だが失敗」を区別できるようになり、呼び出し側の制御フローが明確になった。

### 3. 明示指定 typo の即時検出

`--globals-path` の typo を `--strict` 有無に関わらず例外にしたのは正しい判断。明示的に指定したパスが存在しないのは常にユーザーのミスであり、silent warn で続行するのは有害。`E_EXPLICIT_GLOBALS_PATH_NOT_FOUND` というエラーコードの付与により、catch 側で選択的に処理できるようにしている点も良い。

### 4. テストの充実

8 つの新規テストケースが追加されており、以下のシナリオを網羅的にカバーしている:
- entry CSS 欠落 (strict / 非 strict)
- Tailwind import 欠落 (strict / 非 strict)
- 成功ケース (strict でも exit 0)
- デザインシステムパッケージ未インストール時 (strict でも exit 0)
- `--strict` + `--skip-generate` 併用時の警告
- `sparkle.config.json` の `globals-path` typo (setup 経由)
- 明示 `--globals-path` typo (generate 直接)

### 5. `--strict` + `--skip-generate` 併用時の警告

strict チェック対象がスキップされて事実上無意味になる状態を検知し、ユーザーに警告する配慮がされている。CI の設定ミスを見逃さないための防御策として適切。

---

## 指摘事項

### [HIGH] `raiseOrReturn` のクロージャがスコープ外で参照不能になるリスク

`manageFontImports` 内部で定義されている `raiseOrReturn` は `strict` をクロージャでキャプチャしており、関数としての再利用性がない。現状のコードでは問題にならないが、将来的にこのロジックを別の場所から呼び出す必要が出た場合、`strict` の伝搬が漏れる可能性がある。

**理由**: この関数は「status が failed かつ strict なら throw する」という重要なビジネスロジックを担っているが、`manageFontImports` のローカルスコープに閉じている。将来的に同じパターンが他の場所で必要になった場合、ロジックの重複が発生しうる。

**提案**: 現時点ではこのままで問題ないが、同パターンが 2 箇所以上に出現した場合は、ユーティリティ関数として抽出することを検討してほしい。

### [MEDIUM] `reason` フィールドの値が非構造化文字列

`reason` フィールドに `'write-error: ENOENT'` や `'manage-error: ...'` のようなプレフィックス付き文字列が入る設計になっている。これは将来的にプログラム的な分岐に使いにくい。

```js
return { status: 'failed', reason: `write-error: ${error.code ?? error.message}` };
```

```js
return { status: 'failed', reason: `manage-error: ${error.code ?? error.message}` };
```

**理由**: `reason` が人間向けと機械向けのどちらなのかが曖昧。現状はログ出力くらいでしか使われていないが、今後テストや条件分岐で `reason` を参照する場合、文字列パースが必要になる。

**提案**: `reason` を enum 的な値 (`'write-error'`, `'tailwind-import-missing'` など) に統一し、詳細情報は別フィールド (`detail` など) に分離することを検討してほしい。一部の `reason` 値 (例: `'tailwind-import-missing'`, `'entry-css-not-found'`, `'no-work'`) は既にこの形になっているため、`'write-error: ...'` 系だけ統一すれば整合性が取れる。

### [MEDIUM] `generateCSS` の戻り値が暗黙的に `undefined` になるケース

`manageFontImports` が例外を投げた場合、`generateCSS` の `return { globalsResult }` に到達しないため、呼び出し元は `undefined` を受け取る。`setup.js` の `runGenerate` で `result?.globalsResult` とオプショナルチェイニングを使っているので現状動作はするが、暗黙の `undefined` 返却に依存した設計になっている。

```js
const result = generateCSS(null, null, null, { strict: Boolean(strict) });
return { skipped: false, ran: true, globalsResult: result?.globalsResult };
```

**理由**: `strict` モードでは例外が投げられるため `result` は `undefined` になるが、非 strict で `manageFontImports` が内部エラーをキャッチして `{ status: 'failed', ... }` を返した場合、`generateCSS` は正常に `{ globalsResult }` を返す。この「いつ undefined になるか」がコードから読み取りにくい。

**提案**: `generateCSS` 内で `manageFontImports` の呼び出しを try-catch で囲んで、例外発生時にも明示的な戻り値を返すか、あるいはドキュメントで「strict 時は例外をスローし戻り値は返さない」と明記すると可読性が上がる。

### [LOW] `TAILWIND_NOT_FOUND` メッセージでの相対パス表示

`TAILWIND_NOT_FOUND` の表示パスを `path.relative(process.cwd(), globalsPath)` で計算しているが、`process.cwd()` はプロセス実行時のカレントディレクトリに依存する。CI 環境やモノレポで `cwd` が期待と異なる場合、表示されるパスがわかりにくくなる可能性がある。

```js
const displayPath = path.relative(process.cwd(), globalsPath) || globalsPath;
```

**理由**: 絶対パスが長くて読みにくいという問題を解決するために相対パスにしたこと自体は良い判断だが、`process.cwd()` に暗黙依存している点は認識しておくべき。

**提案**: 現状の実装で問題が出る確率は低いため、そのままで良い。ただし将来問題が報告された場合は、プロジェクトルート（`package.json` の所在ディレクトリ）を基準にすることを検討してほしい。

### [LOW] Prettier による整形変更の混入

`lib/generate-css.js` の差分の大部分は、Prettier の自動整形（アロー関数の括弧追加、オブジェクト配列のインライン化、長い条件式の改行）によるもので、本 PR の機能変更とは関係ない。

```js
-.filter(line => {
+.filter((line) => {
```

```js
-const KNOWN_DESIGN_SYSTEM_PACKAGES = [
-  '@goodpatch/sparkle-design-internal',
-];
+const KNOWN_DESIGN_SYSTEM_PACKAGES = ['@goodpatch/sparkle-design-internal'];
```

**理由**: レビュー時のノイズになり、実質的な変更箇所が見えにくくなる。機能変更と整形変更は別コミットに分けるのがベスト。

**提案**: 今回は既にコミット済みなので対処不要だが、今後は lint/format の修正は別コミットに分離するとレビューしやすくなる。

---

## 設計判断に関する確認事項

### `--strict` のスコープについて

現状 `setup --strict` は generate ステージの失敗のみを検出対象としている（install / scaffold / guard の失敗は従来どおり warn）。CHANGELOG にもこの制限が明記されている。

**質問**: 将来的に `--strict` のスコープを install / scaffold にも拡大する予定はあるか？ その場合、`--strict=generate` のようなスコープ指定オプションにする可能性はあるか？ 現状の bool フラグ設計で後方互換を保てるか確認しておきたい。

### `hasWork` の判定ロジックについて

`manageFontImports` 内の `hasWork` は `sourcePackages` と `customCssPath` だけを見ており、`fontImports`（sparkle-design.css から抽出されるフォント情報）は含まれていない。

```js
const hasWork =
  (sourcePackages \!== null && sourcePackages \!== undefined) || Boolean(customCssPath);
```

**質問**: `fontImports` が存在するが `sourcePackages` も `customCssPath` も空のケースで、entry CSS が見つからないときの挙動は「skipped（正常系）」になる。フォント情報があるにもかかわらず entry CSS がないという状態は、本当に警告不要なのか？

---

## 総評

目的が明確で、後方互換を壊さない形でオプトイン型の strict モードを実現している。内部 API の戻り値リファクタリングも適切で、テストカバレッジも十分。`--globals-path` typo の即時検出は、DX 向上に直結する良い変更。

指摘事項は主にコードの長期保守性に関するもので、現時点での機能的な問題は見当たらない。reason フィールドの構造化と、`generateCSS` の暗黙的な undefined 返却については、次のイテレーションで改善を検討してほしい。

**承認に問題なし。** マージして良い状態。
