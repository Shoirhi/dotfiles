# Neovim Config

ミニマルな Neovim 設定。lazy.nvim でプラグイン管理。

## ディレクトリ構成

```
nvim/
├── init.lua                 -- エントリポイント
└── lua/
    ├── config/
    │   ├── options.lua      -- 基本オプション
    │   └── keymaps.lua      -- キーマップ
    └── plugins/
        ├── colorscheme.lua  -- カラースキーム (catppuccin)
        ├── telescope.lua    -- ファジーファインダー
        ├── treesitter.lua   -- シンタックスハイライト
        ├── mini.lua         -- mini.pairs + mini.surround
        └── oil.lua          -- ファイラー
```

## セットアップ

```bash
# シンボリックリンクを作成
ln -s ~/dotfiles/nvim ~/.config/nvim

# Neovim を起動（初回は自動でプラグインがインストールされる）
nvim
```

前提: Neovim 0.10 以上、`git`、`ripgrep`（Telescope の live_grep 用）

## キーマップ一覧

Leader キーは `Space`。

### 基本操作

| キー | モード | 動作 |
|------|--------|------|
| `<C-h/j/k/l>` | Normal | ウィンドウ間移動 |
| `<S-h>` / `<S-l>` | Normal | 前/次のバッファ |
| `<Esc>` | Normal | 検索ハイライト解除 |
| `<` / `>` | Visual | インデント（選択維持） |
| `J` / `K` | Visual | 行を上下に移動 |
| `<leader>p` | Visual | レジスタを上書きせずペースト |

### Telescope (ファジーファインダー)

| キー | 動作 |
|------|------|
| `<leader>ff` | ファイル検索 |
| `<leader>fg` | テキスト検索 (grep) |
| `<leader>fb` | バッファ一覧 |
| `<leader>fh` | ヘルプタグ検索 |
| `<leader>fr` | 最近開いたファイル |

Telescope 操作中:

| キー | 動作 |
|------|------|
| `<C-n>` / `<C-p>` | 次/前の候補 |
| `<CR>` | 選択して開く |
| `<C-x>` | 水平分割で開く |
| `<C-v>` | 垂直分割で開く |
| `<Esc>` | 閉じる |

### Oil (ファイラー)

| キー | 動作 |
|------|------|
| `-` | ファイラーを開く（現在のファイルのディレクトリ） |
| `<CR>` | ファイルを開く / ディレクトリに入る |
| `-` | 親ディレクトリに戻る |
| `g.` | 隠しファイルの表示切替 |

Oil ではファイル操作をバッファ編集として行える:

- ファイル名を編集 -> リネーム
- 行を削除 (`dd`) -> ファイル削除
- 行をヤンク+ペースト -> ファイルの移動/コピー
- 変更を保存 (`:w`) で実際に反映される

### mini.surround (囲み文字操作)

| キー | 動作 | 例 |
|------|------|----|
| `sa` | 囲みを追加 | `saiw"` -> word を `"word"` に |
| `sd` | 囲みを削除 | `sd"` -> `"word"` を `word` に |
| `sr` | 囲みを置換 | `sr"'` -> `"word"` を `'word'` に |

`iw` はテキストオブジェクト（inner word）。`i"`, `i(`, `it`（タグ）なども使える。

## よく使うテクニック

### マルチファイル置換

```
1. <leader>fg で検索
2. <C-q> で結果を quickfix リストに送る
3. :cdo s/old/new/g | update
```

### 矩形選択 (Visual Block)

```
1. <C-v> で矩形選択モードに入る
2. 範囲を選択
3. I で先頭に挿入 / A で末尾に挿入
4. <Esc> で全行に反映
```

### テキストオブジェクト

Vim の強力な概念。`動作` + `範囲` + `対象` で操作する。

| コマンド | 動作 |
|----------|------|
| `ciw` | カーソル上の単語を変更 (change inner word) |
| `ci"` | `"..."` の中身を変更 |
| `ci(` | `(...)` の中身を変更 |
| `da{` | `{...}` を括弧ごと削除 |
| `vi[` | `[...]` の中身を選択 |
| `yap` | 段落全体をコピー (yank a paragraph) |

### レジスタ

```
"ayy    -- a レジスタに行をコピー
"ap     -- a レジスタからペースト
"+y     -- システムクリップボードにコピー
:reg    -- レジスタ一覧を表示
```

### マクロ

```
qa      -- a レジスタにマクロ記録開始
(操作)
q       -- 記録終了
@a      -- マクロ再生
@@      -- 直前のマクロを再生
10@a    -- 10回繰り返す
```

### ウィンドウ操作

| キー | 動作 |
|------|------|
| `:sp` | 水平分割 |
| `:vsp` | 垂直分割 |
| `<C-w>=` | ウィンドウサイズを均等に |
| `<C-w>o` | 他のウィンドウをすべて閉じる |
| `<C-w>T` | 現在のウィンドウを新しいタブに |

## プラグインの追加方法

`lua/plugins/` に新しい `.lua` ファイルを作成する。lazy.nvim が自動で読み込む。

```lua
-- lua/plugins/example.lua
return {
  {
    "author/plugin-name",
    opts = {},
  },
}
```

次回 Neovim 起動時に自動インストールされる。
`:Lazy` でプラグイン管理画面を開ける。

## Treesitter で言語を追加

`lua/plugins/treesitter.lua` の `ensure_installed` にパーサー名を追加する。

```lua
ensure_installed = {
  "lua",
  "javascript",  -- 追加
  "typescript",  -- 追加
  -- ...
},
```

追加後、Neovim を再起動するか `:TSUpdate` を実行。
