# Strap 標準カラーパレット

Strap ウェブアプリで使用されている標準カラーパレット。
これらは推奨値であり、必ずしも使う必要はない。ユーザーのカラー指定が抽象的な場合（「赤」「青っぽい色」など）の参考値として使用する。
任意の `#RRGGBB` / `#RRGGBBAA` 値を自由に指定できる。

## 図形・テキスト・コネクタ・罫線

| Color | Lightest | Lighter | Normal | Darker | Darkest |
|-------|----------|---------|--------|--------|---------|
| Red | `#FFE9EF` | `#FFC9D3` | `#F26371` | `#E1012D` | `#C40019` |
| Orange | `#FFE1B2` | `#FFCD80` | `#F26D00` | `#E95201` | `#D94501` |
| Yellow | `#FEF9C5` | `#FDF17A` | `#FDDB42` | `#F9C339` | `#F8AB30` |
| Green | `#E0F2F4` | `#B1DEE1` | `#00A5A7` | `#008888` | `#006866` |
| Blue | `#E7EAFE` | `#C5CBFD` | `#436AF9` | `#0045E9` | `#002ED2` |
| Purple | `#EEE7F9` | `#D4C4EF` | `#8354D4` | `#602FC5` | `#4521B5` |
| Gray | `#EDEDF1` | `#D1D4DC` | `#828599` | `#4E5061` | `#292A34` |
| White | `#FFFFFF` | — | — | — | — |

- Normal がデフォルト色。Lightest〜Darkest はカラーステップ（濃淡バリエーション）
- テキスト色のデフォルト: 濃い色の図形は白 `#FFFFFF`、薄い色の図形は同色の Darkest
- Yellow のテキスト色は `#6B3000`（専用）

## 付箋カラーパレット（図形とは異なる）

| Color | fillColor | textColor |
|-------|-----------|-----------|
| Red | `#FFB5BC` | `#292C33` |
| Orange | `#FFCB9C` | `#292C33` |
| Yellow | `#FFE38F` | `#292C33` |
| Green | `#9BE0B9` | `#292C33` |
| Blue | `#ABD9FF` | `#292C33` |
| Purple | `#CEB2FF` | `#292C33` |
| Gray | `#D3D6E7` | `#292C33` |
| Black | `#5E677E` | `#FFFFFF` |
| White | `#FFFFFF` | `#292C33` |
