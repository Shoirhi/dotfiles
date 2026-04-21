## PR Review: #26 ci: GitHub Actions で CI / Publish を自動化し beta チャネルを追加

### 変更サマリー

このPRは、sparkle-design-cli の開発・リリースプロセスを手動からCI/CD自動化へ移行する変更である。具体的には以下の3つの柱で構成される。

1. **CI ワークフロー** (`.github/workflows/ci.yml`): push(main) と PR をトリガーに lint + test を自動実行。private git submodule (`sparkle-variables`) を deploy key 経由で取得する仕組みを含む。
2. **Publish ワークフロー** (`.github/workflows/publish.yml`): `workflow_dispatch` による手動トリガーで npm publish を実行。`package.json` の version から dist-tag (`latest` / `beta`) を自動判定し、不整合な組み合わせ（prerelease を latest に publish するなど）をガードする。
3. **lint クリーンアップとドキュメント整備**: CI 導入の前提として既存の eslint エラーを解消 (`FONT_DEFAULTS` 未使用 import 削除、`createFontImportBlock` dead code 削除、`no-unused-vars` の ignore パターン拡充)。README にリリースチャネル説明とメンテナ向けリリース手順を追加。

変更ファイル: 6ファイル (+219 / -11)

---

### レビューコメント

**[praise]** `.github/workflows/publish.yml`:62-96

dist-tag の自動判定ロジックが堅実に設計されている。`auto` モードで version 文字列からチャネルを推論しつつ、安定版を beta に publish したり prerelease を latest に publish するケースをエラーで止めるガード条件が網羅的に書かれている。手動オペレーションのミスを仕組みで防ぐ設計思想は、チーム全体の参考になる良いパターンである。

---

**[praise]** `.github/workflows/publish.yml`:97-102

`inputs.channel` を直接シェルに展開せず `env` 経由で渡している点が良い。GitHub Actions の `inputs` をシェル変数に直接展開するとインジェクションリスクがあるため、セキュリティの観点から適切な対策である。

---

**[question]** `.github/workflows/ci.yml` / `.github/workflows/publish.yml` 全体

deploy key によるsubmodule取得のロジックが `ci.yml` と `publish.yml` で完全に重複している（"Prepare deploy key" ステップと "Fetch submodules" ステップ）。現時点では2箇所だが、今後ワークフローが増えた場合にメンテナンスコストが上がる可能性がある。composite action や reusable workflow として共通化する設計は検討されたか？ 現時点の2ファイルであれば許容範囲とも思えるが、チームの方針を確認したい。

---

**[concern]** `.github/workflows/ci.yml`:16-17

`SUBMODULE_SSH_KEY` シークレットが未設定の場合の挙動が気になる。PR がフォークリポジトリから送られた場合、シークレットにアクセスできず `DEPLOY_KEY` が空文字列になり、`printf '%s\n' ""` で空の鍵ファイルが作成され、`git submodule update` が不明瞭なエラーで失敗する可能性がある。外部コントリビューターからのPRを想定しない（private リポジトリ or チーム内のみ）という前提であれば問題ないが、その前提をワークフロー内のコメントや PR description に明示しておくと、将来の混乱を防げる。

---

**[suggestion]** `.github/workflows/publish.yml`:71-72

`*-*` のパターンで prerelease 全般を捕捉しているが、`-beta.*` 以外の prerelease（例: `-alpha.1`, `-rc.1`）は `unsupported` として弾かれる設計になっている。これは意図的な制限と読み取れるが、将来 `-rc.N` のようなリリース候補を導入する可能性がある場合、この case 文の拡張が必要になる。現時点でのチームの運用方針として beta 以外の prerelease は不要という判断であれば問題ないが、PR description やコード内コメントにその意思決定の理由（「現時点では beta チャネルのみサポート」等）を残しておくと、後から見たときに "なぜ alpha/rc を除外したのか" が分かりやすくなる。

---

**[question]** `.github/workflows/publish.yml` 全体

publish ワークフローでは lint と test を実行した後に `npm publish` を行っているが、CI ワークフロー（push/PR トリガー）でも lint + test は実行される。publish は `workflow_dispatch`（手動トリガー）のため、main マージ後に実行される想定であり、その時点で CI は既に通過しているはず。publish ワークフロー内で改めて lint + test を実行する設計意図は何か？ 「publish 時点のコードが必ずグリーンであることを保証する」安全策であれば理にかなっているが、その意図をワークフロー内のコメントに残しておくと良い。

---

**[nit]** `README.md`:51-52 / 405-415

Beta から GA への昇格手順について、上部では「`X.Y.Z` を改めて publish します」と記載されている一方、下部の「Beta から GA（latest）へ昇格」セクションでは「選択肢 A: 新たに X.Y.Z を publish する」と「選択肢 B: 既存の beta に latest タグを付け替える」の2通りが提示されている。推奨フローを1つに統一するか、上部の説明でも2通りあることに触れておくと、ドキュメント全体の一貫性が高まる。

---

**[concern]** `README.md`:386-394 / PR description

PR description に「`NPM_TOKEN` の登録が必要」と明記されている点は良いが、README のメンテナ向けリリース手順には `NPM_TOKEN` の設定が前提条件として記載されていない。メンテナが README だけを見て操作した場合、トークン未設定のまま publish を実行して失敗する可能性がある。リリース手順の冒頭に前提条件（`NPM_TOKEN` と `SUBMODULE_SSH_KEY` の設定）を明記することを推奨する。

---

**[praise]** `lib/font-manager.js` / `eslint.config.js`

CI 導入に先立ち、既存の lint エラーを先にクリーンアップしてからワークフローを追加するという段取りが良い。CI を導入した瞬間に大量のエラーで赤くなる、という状況を避ける堅実なアプローチである。`createFontImportBlock` のような dead code も見逃さず削除されている。

---

### 総評

**全体的な印象**: 手動で行っていた npm publish を GitHub Actions に移行し、beta チャネルによる段階的リリースを可能にする、運用面で価値の高い変更である。ワークフローの設計は堅実で、セキュリティ（env 経由の入力受け渡し）、安全性（dist-tag の不整合ガード）、運用性（auto 判定モード）のバランスが良く取れている。

**特に良かった点**:
- dist-tag の自動判定と不整合ガードのロジックが明快で、ヒューマンエラーを仕組みで防いでいる
- `inputs.channel` を env 経由で渡すセキュリティ対策
- CI 導入前の lint クリーンアップという段取りの良さ
- PR description の記述が充実しており、変更の意図と背景が明確に伝わる

**マージ前に確認・対応してほしい点**:
- README のリリース手順に `NPM_TOKEN` / `SUBMODULE_SSH_KEY` の前提条件を明記する（[concern]）
- フォークからの PR 時に deploy key が空になるケースの想定を確認し、必要に応じてコメントで前提を明示する（[concern]）
- publish ワークフロー内の lint + test 再実行の意図をコメントで補足する（[question] -- 対応は任意）
