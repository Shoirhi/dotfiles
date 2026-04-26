---
name: figma-refactor
description: |
  Figma URL を受け取り、対象ノードのレイヤー構造を解析してベストプラクティスに沿ってリファクタリング（リネーム、グルーピング、不要ネスト解消、Auto Layout 適用）し、Figma デザインを直接上書きするスキル。
  ユーザーが Figma のレイヤー整理、ノード名のクリーンアップ、構造のリファクタリング、デザインファイルの整頓を依頼したときに使う。「Figma 整理して」「レイヤー名を直して」「ノード構造をきれいにして」「Figma リファクタ」などの指示で発動する。
---

# Figma Design Refactoring

Figma デザインのノード構造を解析し、ベストプラクティスに沿って自動リファクタリングする。

## 概要

デザイナーが作業中に生まれる「Group 123」「Frame 45」「Rectangle 7」のような仮名や、フラットすぎる階層、冗長なネスト、名前の重複を検出し、Figma Plugin API 経由で直接修正する。見た目（ビジュアル）は一切変えず、レイヤーパネル上の構造だけを改善する。

## ワークフロー

### Step 1: URL をパースする

ユーザーから Figma URL を受け取り、`fileKey` と `nodeId` を抽出する。

- `figma.com/design/:fileKey/:fileName?node-id=:nodeId`
  - nodeId の `-` は `:` に変換する（例: `443-1478` -> `443:1478`）
- branch URL の場合: `figma.com/design/:fileKey/branch/:branchKey/:fileName` -> branchKey を fileKey として使う

### Step 2: 現状を把握する

1. `get_metadata` で対象ノードのツリー構造（XML形式）を取得する
2. `get_screenshot` で現在の見た目をスクリーンショットとして保存する（リファクタ後の比較用）

### Step 3: 問題を分析する

メタデータのXMLを読み、以下の問題を洗い出す。

#### 3-1. ジェネリック名の検出

以下のパターンに一致するノード名はジェネリック（意味のない仮名）と判定する:

- `Group N` (例: Group 343, Group 83)
- `Frame N` (例: Frame 42, Frame 47)
- `Rectangle N` (例: Rectangle 7, Rectangle 9)
- `Ellipse N`
- `Line N` (例: Line 6, Line 7)
- `Vector N`
- `Polygon N`

ただし以下は対象外:
- コンポーネント名やインスタンス名
- 意図的にそう名付けられたと判断できるもの（例: 既にセマンティックな名前）
- `_` で始まる名前（Figma の慣習で非表示/内部用を示す）

#### 3-2. フラット構造の検出

ルートノード直下に多数（8個以上）のセクション的な要素が並んでいる場合、ページセクションとしてのグルーピングが不足している可能性がある。ただし、ページ全体の構造として意図的にフラットにしている場合もあるので、視覚的なセクション境界（背景矩形、Y座標の区切り）を手がかりに判断する。

#### 3-3. 冗長ネストの検出

- 子が1つだけのグループ/フレーム（ラッパーだけで意味がない入れ子）
- ただし、マスクグループ、Auto Layout コンテナ、クリッピング用フレームなど、構造的に意味のあるシングルチャイルドは除外する

#### 3-4. 名前重複の検出

同じ親の中に同名のノードが複数ある場合（例: 複数の "Group 10"）、区別できるようリネームが必要。

### Step 4: リネーム計画を立てる

ジェネリック名のノードに対して、意味のある名前を推論する。命名のヒント:

1. **テキスト子要素の内容**: ノードの中にテキストがあれば、その内容を要約して名前にする
   - 例: テキスト「松岡塾 開催案内」を含む Group -> `section-heading/information`
2. **視覚的な役割**: 背景矩形なら `bg`、区切り線なら `divider`、アイコンなら `icon`
3. **ページ上の位置と文脈**: ヘッダー領域なら `header`、フッターなら `footer`
4. **繰り返しパターン**: 同じ構造が複数並んでいればリスト項目として連番（例: `testimonial-card/1`, `testimonial-card/2`）
5. **セクション**: ページ内の大きなブロックは `section/` プレフィックスを付ける（例: `section/hero`, `section/faq`, `section/footer`）

命名規則:
- kebab-case を使う（例: `cta-button`, `price-card`）
- Figma の `/` 区切りでグルーピングを表現する（例: `section/curriculum`, `card/testimonial-1`）
- 短く明確に（長くても30文字以内）
- 日本語のテキスト内容はそのまま使わず、英語で意味を表現する

### Step 5: use_figma でリファクタリングを実行する

`use_figma` ツールで Figma Plugin API の JavaScript を実行して修正を適用する。

以下の順序で実行する（順序が重要 -- 構造変更は名前変更の後に行う方が安全）:

#### 5-1. レイヤー名のリネーム

```javascript
// ノードIDでノードを取得してリネーム
const node = figma.getNodeById("443:1479");
if (node) node.name = "section/cta-hero";
```

一度に大量のリネームを行う場合はバッチにまとめる（1回のuse_figma呼び出しで最大50ノード程度）。

#### 5-2. 冗長ネストの解消

子が1つだけの無意味なラッパーを解消する。ただし以下に注意:
- 解消前にラッパーにクリッピングやマスク、エフェクトが設定されていないか確認する
- 子の位置（absoluteTransform）を保持する
- 安全でない場合はスキップする

```javascript
const wrapper = figma.getNodeById("...");
if (wrapper && wrapper.children && wrapper.children.length === 1) {
  const child = wrapper.children[0];
  const parent = wrapper.parent;
  const index = parent.children.indexOf(wrapper);
  // ラッパーにエフェクトやクリッピングがなければ解消
  if (!wrapper.clipsContent && wrapper.effects.length === 0) {
    parent.insertChild(index, child);
    wrapper.remove();
  }
}
```

#### 5-3. Auto Layout の適用（安全な場合のみ）

Auto Layout は見た目を壊すリスクがあるため、以下の条件をすべて満たす場合のみ適用する:

- 子要素が同一方向（水平 or 垂直）に等間隔で並んでいる
- 子要素のサイズが統一されている（カードリストなど）
- 子要素の数が2個以上
- 既に Auto Layout が適用されていない

```javascript
const frame = figma.getNodeById("...");
if (frame && frame.type === "FRAME" && frame.layoutMode === "NONE") {
  // 子要素の配置を分析して安全なら適用
  frame.layoutMode = "HORIZONTAL"; // or "VERTICAL"
  frame.itemSpacing = 40; // 子要素間のギャップ（計算値）
  frame.primaryAxisAlignItems = "MIN";
  frame.counterAxisAlignItems = "MIN";
}
```

安全性チェック:
1. 子要素の X 座標（水平配置の場合）または Y 座標（垂直配置の場合）が等間隔かチェック
2. 許容誤差は 2px
3. 子要素に absolutePosition が設定されているものがあればスキップ
4. 判断に迷ったらスキップ（安全側に倒す）

### Step 6: 結果を確認する

1. リファクタリング後に再度 `get_screenshot` で見た目を確認する
2. ビジュアルが変わっていないことを確認する
3. 変更内容のサマリーをユーザーに報告する:
   - リネームしたノード数と代表例
   - 解消した冗長ネストの数
   - 適用した Auto Layout の箇所
   - スキップした項目とその理由

## 制約と注意事項

- **ビジュアルを変えない**: レイヤー名と構造の整理のみ。色、フォント、サイズ、位置の変更は行わない
- **コンポーネントは触らない**: コンポーネント定義やインスタンスのオーバーライドは変更しない
- **段階的に実行**: 大きなノードツリーは複数回の `use_figma` 呼び出しに分割する。1回あたりのコード量が多すぎるとタイムアウトする
- **エラー時は中断**: `use_figma` がエラーを返したら、残りの変更は中止してユーザーに報告する
- **Undo 可能**: Figma の Undo (Cmd+Z) で元に戻せることをユーザーに伝える
