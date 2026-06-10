# Phase 2: デザイントークン・方針決定

## 目的

Phase 1 で選択された方向性をデザイントークンとして形式化し、全画面で一貫したデザインを実現するための基盤を作る。

## Step 1: デザイントークンの定義

出力先: `spec/design/tokens.md`

ユーザーが選んだ方向性（とフィードバック）をもとに、以下のトークンを定義する:

### カラー
- **Primary**: メインカラー（ブランドカラー）とそのバリエーション（lighter, light, default, dark, darker）
- **Accent**: アクセントカラー（CTA、重要な要素に使用）
- **Neutral**: テキスト、背景、ボーダーなどに使うニュートラルカラーのスケール
- **Semantic**: Success, Warning, Error, Info
- **Background**: ページ背景、カード背景、セクション背景

値は OKLCH で定義し、必要に応じて HEX も併記する。

### タイポグラフィ
- **Font Family**: 見出し用、本文用（Google Fonts から選定、具体的なフォント名を指定）
- **Font Size Scale**: 基準サイズと各レベルのサイズ（clamp() を使った流動的サイズ推奨）
- **Font Weight**: 各用途でのウェイト
- **Line Height**: 見出し用、本文用
- **Letter Spacing**: 必要に応じて

### スペーシング
- **Base Unit**: 基準となるスペーシング単位（例: 4px, 8px）
- **Scale**: 各レベルのスペーシング値（xs, sm, md, lg, xl, 2xl, ...）
- **Section Spacing**: セクション間のスペーシング

### ブレークポイント

業界標準のブレークポイントを採用する。モバイルファーストの `min-width` ベースで、未指定（〜640px未満）がモバイルの基準スタイル。

| 名前 | 最小幅 | メディアクエリ | 想定デバイス |
|------|--------|----------------|--------------|
| (base) | 0px | （未指定） | スマートフォン縦 |
| `sm` | 640px | `@media (min-width: 640px)` | 大型スマートフォン横〜小型タブレット縦 |
| `md` | 768px | `@media (min-width: 768px)` | タブレット縦 |
| `lg` | 1024px | `@media (min-width: 1024px)` | タブレット横〜小型ラップトップ |
| `xl` | 1280px | `@media (min-width: 1280px)` | デスクトップ |
| `2xl` | 1536px | `@media (min-width: 1536px)` | 大型ディスプレイ |

ブレークポイント値はプロジェクト固有の事情がない限り変更しない。画面間で同じ値を使う。

### その他
- **Border Radius**: 小・中・大・円形
- **Shadow**: 使用するシャドウのレベル（使う場合）
- **Transition**: デフォルトのトランジション設定
- **Container**: 最大コンテンツ幅（例: `max-width: min(100% - 2rem, 1200px)`）

### CSS カスタムプロパティの命名規則

Phase 3 で各HTMLに転記する際の統一的な命名規則を定める。tokens.md にこの命名規則を記載し、全画面で同じプロパティ名を使う:

```css
:root {
  /* カラー */
  --color-primary-lighter: oklch(...);
  --color-primary-light: oklch(...);
  --color-primary: oklch(...);
  --color-primary-dark: oklch(...);
  --color-primary-darker: oklch(...);
  --color-accent: oklch(...);
  --color-neutral-50: oklch(...);
  --color-neutral-100: oklch(...);
  /* ... 50刻みで 900 まで */
  --color-success: oklch(...);
  --color-warning: oklch(...);
  --color-error: oklch(...);
  --color-info: oklch(...);
  --color-bg-page: oklch(...);
  --color-bg-card: oklch(...);
  --color-bg-section: oklch(...);

  /* タイポグラフィ */
  --font-heading: 'フォント名', serif;
  --font-body: 'フォント名', sans-serif;
  --text-xs: clamp(...);
  --text-sm: clamp(...);
  --text-base: clamp(...);
  --text-lg: clamp(...);
  --text-xl: clamp(...);
  --text-2xl: clamp(...);
  --text-3xl: clamp(...);
  --leading-tight: 1.2;
  --leading-normal: 1.6;

  /* スペーシング */
  --space-xs: ...;
  --space-sm: ...;
  --space-md: ...;
  --space-lg: ...;
  --space-xl: ...;
  --space-2xl: ...;
  --space-section: ...;

  /* その他 */
  --radius-sm: ...;
  --radius-md: ...;
  --radius-lg: ...;
  --radius-full: 9999px;
  --shadow-sm: ...;
  --shadow-md: ...;
  --shadow-lg: ...;
  --transition-default: ...;

  /* ブレークポイント（参照用。メディアクエリ内では数値を直接使う） */
  --bp-sm: 640px;
  --bp-md: 768px;
  --bp-lg: 1024px;
  --bp-xl: 1280px;
  --bp-2xl: 1536px;

  /* コンテナ */
  --container-max: 1280px;
  --container-padding: clamp(1rem, 4vw, 2rem);
}
```

CSS カスタムプロパティは標準のメディアクエリ条件式では使用できないため、メディアクエリのブレークポイント値は `@media (min-width: 640px)` のように数値リテラルで記述する。tokens.md にこの値を一元化して参照元とする。

実際の値は Phase 1 のドラフトから抽出・調整する。命名規則はプロジェクトに応じて調整可能だが、tokens.md に定義したものを正とする。

## Step 2: デザイン方針の策定

出力先: `spec/design/index.md`

トークンだけでは表現できないデザイン上の判断基準を方針としてまとめる:

- **全体のトーン・雰囲気**: Phase 1 で選ばれた方向性を言語化
- **レイアウトの原則**: グリッドの使い方、余白の取り方、非対称の活用方針
- **レスポンシブ戦略**: モバイルファースト前提で、各ブレークポイントで何が変わるか（カラム数の変化、ナビゲーション形態の切替、フォントスケールの調整、画像のトリミング・差し替え方針など）。タッチターゲットの最小サイズ（指でタップしやすい大きさを考慮）、モバイル時のスティッキー要素の扱い、横スクロール回避の原則も含める
- **インタラクションの方針**: ホバー、フォーカス、トランジションの方向性。タッチデバイスではホバーに依存しないことを明記
- **画像・アイコンの方針**: スタイル、サイズ感、使用基準、レスポンシブ時の振る舞い（`object-fit`, `srcset` の方針など）
- **アクセシビリティ**: コントラスト比の基準（WCAG AA 以上）、フォーカス表示の方針
- **スコープ外の明示**: ダークモードなど、このフェーズで扱わない項目を明記（レスポンシブはスコープ内）
- **参照するトークン**: `spec/design/tokens.md` へのリンク

トークンと方針の作成が完了したら、ユーザーに確認を取らずそのまま Phase 3 に進む。
ユーザーが選んだドラフトの方向性を忠実に反映していれば、追加の承認は不要。
