---
name: viewport-debounce
description: スマホ対応のビューポート縮小スクリプトを生成する。debounceでリサイズイベントを間引きつつ、指定幅以下でviewport metaタグを書き換えてページを縮小表示する。「Debounceでビューポート調整」「スマホサイズ以下で縮小」「小さい画面でスケールダウン」「レスポンシブでviewport変更」「モバイルで縮小表示したい」「リサイズ時にviewport切り替え」のような指示で使う。ビューポートやdebounce、スマホ縮小に関する話題が出たら積極的に使うこと。
---

# Viewport Debounce

リサイズイベントをdebounceで間引きながら、画面幅が閾値より小さい場合にviewport metaタグを書き換えてページを縮小表示するスクリプトを生成するスキル。

## 背景

スマートフォンなど小さい画面で、デスクトップ向けレイアウトを崩さずに閲覧させたい場合がある。viewport metaタグの`width`を固定値にすることで、ブラウザにページ全体を縮小描画させられる。ただし`resize`イベントは高頻度で発火するため、debounceで処理を間引かないとパフォーマンスが悪化する。

## パラメータ

| パラメータ | デフォルト | 説明 |
|-----------|-----------|------|
| triggerWidth | 375 | この幅(px)未満でビューポートを固定幅に切り替える |
| debounceDelay | 300 | debounceの遅延時間(ms) |
| lang | js | `js` または `ts` |

ユーザーが「768px以下で」のように幅を指定した場合はtriggerWidthをその値にする。指定がなければ375pxを使う。TypeScriptで書いてと言われたら型定義付きで出力する。

## 生成するコード

### JavaScript版

```javascript
function debounce(func, timeout) {
  let timer;
  timeout = timeout !== undefined ? timeout : 300;
  return function () {
    const context = this;
    const args = arguments;
    clearTimeout(timer);
    timer = setTimeout(function () {
      func.apply(context, args);
    }, timeout);
  };
}

const adjustViewport = function () {
  const triggerWidth = 375;
  const viewport = document.querySelector('meta[name="viewport"]');
  if (!viewport) return;
  const value =
    window.outerWidth < triggerWidth
      ? 'width=' + triggerWidth + ', target-densitydpi=device-dpi'
      : 'width=device-width, initial-scale=1';
  viewport.setAttribute('content', value);
};

window.addEventListener('resize', debounce(adjustViewport, 300), false);
adjustViewport();
```

### TypeScript版

```typescript
function debounce<T extends (...args: unknown[]) => void>(
  func: T,
  timeout: number = 300
): (...args: Parameters<T>) => void {
  let timer: ReturnType<typeof setTimeout> | undefined;
  return function (this: unknown, ...args: Parameters<T>): void {
    clearTimeout(timer);
    timer = setTimeout(() => {
      func.apply(this, args);
    }, timeout);
  };
}

const adjustViewport = (): void => {
  const triggerWidth: number = 375;
  const viewport = document.querySelector<HTMLMetaElement>(
    'meta[name="viewport"]'
  );
  if (!viewport) return;
  const value: string =
    window.outerWidth < triggerWidth
      ? `width=${triggerWidth}, target-densitydpi=device-dpi`
      : 'width=device-width, initial-scale=1';
  viewport.setAttribute('content', value);
};

window.addEventListener('resize', debounce(adjustViewport, 300), false);
adjustViewport();
```

## 生成ルール

1. triggerWidthの値をユーザー指定に合わせて変更する
2. debounceDelayもユーザー指定があれば変更する
3. viewport metaタグが存在しない場合のガード(`if (!viewport) return`)を必ず含める
4. 初期表示時にも`adjustViewport()`を1回呼ぶ（ページ読み込み時にも適用するため）
5. コード内にコメントを入れすぎない。必要最小限にする
6. ユーザーのプロジェクトにすでにdebounceユーティリティがある場合は、それをインポートして使う方が望ましい旨を伝える
7. `target-densitydpi`は非標準だが、一部の古いAndroidブラウザで必要。不要と判断される場合はユーザーに確認する

## 設置場所の提案

ユーザーがどこにコードを置くか聞いてきた場合:

- WordPressテーマ: `functions.php`で`wp_enqueue_script`するか、テーマの`footer.php`末尾に`<script>`で配置
- 静的サイト: `</body>`直前に`<script>`で配置
- SPA (React/Vue等): エントリーポイント（`main.ts`や`App.tsx`）の`useEffect`やマウント時に実行
- Next.js: `_app.tsx`の`useEffect`内、または`Script`コンポーネントで配置
