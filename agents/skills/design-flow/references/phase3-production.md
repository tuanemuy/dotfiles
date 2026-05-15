# Phase 3: デザイン作成

## 目的

Phase 2 で定義したトークンと方針に基づき、全画面のHTMLデザインを作成する。

## Step 1: 画面ごとのHTMLデザイン作成

Phase 0 で整理した画面一覧の各画面について、Skill ツールで `/frontend-design` を呼び出してHTMLファイルを作成する。

出力先: `spec/design/pages/{画面名}.html`

`/frontend-design` に渡すコンテキスト:
- **デザイン対象**: 画面名と、`spec/pages/index.md` に記載されたその画面の目的・機能
- **ユーザーシナリオ**: `spec/scenario/` からこの画面に関連するシナリオの要約
- **デザイントークン**: `spec/design/tokens.md` の内容（CSS カスタムプロパティの命名規則を含む）
- **デザイン方針**: `spec/design/index.md` の内容
- **出力先パス**: 上記の出力先
- **作成条件**: 下記の条件をすべて伝える

作成条件:
- 1つのHTMLファイルに CSS をインラインで含め、単体でブラウザ表示できるようにする
- `spec/design/tokens.md` のトークン値を CSS カスタムプロパティとして定義し、全体で参照する
- `spec/design/index.md` の方針（レスポンシブ戦略を含む）に沿う
- ダミーデータを使ってリアルな見た目にする
- **レスポンシブ対応必須**: 標準ブレークポイント（`sm: 640px` / `md: 768px` / `lg: 1024px` / `xl: 1280px` / `2xl: 1536px`）でモバイル・タブレット・デスクトップの全レンジで破綻なく動作すること。モバイルファーストで基本スタイルを記述し、`@media (min-width: 640px)`、`@media (min-width: 768px)`、`@media (min-width: 1024px)`、`@media (min-width: 1280px)`、`@media (min-width: 1536px)` で必要な箇所のみ拡張する（すべてのブレークポイントを必ず使う必要はない）
- `<meta name="viewport" content="width=device-width, initial-scale=1">` を必ず含める

### トークンの適用

HTMLの `<style>` セクションで CSS カスタムプロパティとしてトークンを定義し、全体で参照する。
`spec/design/tokens.md` に定義された命名規則をそのまま使う。ハードコードされた値は使わない。

```html
<style>
  :root {
    /* spec/design/tokens.md から転記 */
    --color-primary: oklch(...);
    --color-accent: oklch(...);
    --font-heading: 'フォント名', serif;
    --font-body: 'フォント名', sans-serif;
    --space-md: ...;
    /* ... */
  }
</style>
```

### インタラクション状態

主要なインタラクティブ要素には、以下の状態をデザインに含める:
- **ホバー**: ボタン、リンク、カードなど
- **フォーカス**: フォーム要素、ナビゲーション（アクセシビリティのためにフォーカスリングを明示する）
- **アクティブ**: ボタン押下時
- **無効**: disabled 状態のフォーム要素やボタン
- **エラー**: フォームバリデーションエラー時の表示

`spec/design/index.md` のインタラクション方針に従い、トークンの transition 値を使う。

### 画面間の一貫性

共通要素（ヘッダー、ナビゲーション、フッターなど）は画面間で統一する。
ドラフト段階と異なり、ここでは全画面がひとつのプロダクトとして一貫して見えることが重要。

### レスポンシブ実装の指針

- **モバイルファースト**: ベーススタイルはモバイル幅を想定。`@media (min-width: 640px)` (sm), `@media (min-width: 768px)` (md), `@media (min-width: 1024px)` (lg), `@media (min-width: 1280px)` (xl), `@media (min-width: 1536px)` (2xl) で段階的に拡張する。`max-width` ベースの記述は避ける
- **流動的レイアウト**: 固定 px 幅ではなく Flexbox / CSS Grid、`%`、`fr`、`minmax()`、`clamp()` を使う。例: `grid-template-columns: repeat(auto-fit, minmax(min(100%, 280px), 1fr))`
- **流動的タイポグラフィ**: フォントサイズに `clamp(min, preferred, max)` を活用し、ブレークポイントごとに `font-size` を切り替える数を減らす
- **ナビゲーション**: モバイル時はハンバーガーメニューやボトムナビ等への切替を `spec/design/index.md` の方針に従って実装する
- **タッチターゲット**: モバイル時のボタン・リンクは 44×44px 以上を確保
- **画像・メディア**: `max-width: 100%; height: auto;` を基本とし、固定サイズで突き抜けないようにする
- **テーブル・ワイドコンテンツ**: モバイルではカードレイアウトへの変換、または横スクロール（コンテナに `overflow-x: auto`）で対応
- **横スクロール禁止**: `body` や主要コンテナで意図しない横スクロールが発生しないよう確認する

## Step 2: スクリーンショットの取得と視覚的確認

全画面のHTMLデザインを作成したら、agent-browserで開いて**モバイル・タブレット・デスクトップの3サイズ**でスクリーンショットを取得する。
コードだけでは見落とす視覚的な問題（レイアウト崩れ、余白の不均一、色のバランス、レスポンシブ時の破綻等）を確認する。

各画面について、各ブレークポイントを跨ぐ以下のビューポートで取得する:
- モバイル: 375×667（`sm` 未満。基準のモバイル幅）
- タブレット: 768×1024（`md` ジャストヒット）
- デスクトップ: 1280×800（`xl` ジャストヒット。`lg` 表示も含む）

```bash
agent-browser --session design-page-{画面名} open file:///absolute/path/to/spec/design/pages/{画面名}.html

agent-browser --session design-page-{画面名} viewport 375 667
agent-browser --session design-page-{画面名} screenshot /tmp/design-screenshots/pages/{画面名}-mobile.png

agent-browser --session design-page-{画面名} viewport 768 1024
agent-browser --session design-page-{画面名} screenshot /tmp/design-screenshots/pages/{画面名}-tablet.png

agent-browser --session design-page-{画面名} viewport 1280 800
agent-browser --session design-page-{画面名} screenshot /tmp/design-screenshots/pages/{画面名}-desktop.png

agent-browser --session design-page-{画面名} close
```

`2xl` (1536px) を本格的に活用するデザインの場合は、`1536×960` のワイドビューポートも追加で取得する。

スクリーンショットの保存先: `/tmp/design-screenshots/pages/`
命名規則: `{画面名}-desktop.png`, `{画面名}-tablet.png`, `{画面名}-mobile.png`

agent-browser に `viewport` サブコマンドが無い場合は CLI ヘルプで該当オプション（`--width`/`--height`、`--device` など）を確認して同等のことを行う。

画面数が多い場合、サブエージェントに委譲して並列でスクリーンショットを取得してもよい（最大3並列）。

スクリーンショットを Read ツールで確認し、以下の視覚的チェックを行う:

- 各ビューポートでレイアウトが意図通りに表示されているか
- 要素の配置・アラインメントに問題がないか
- カラーバランスは自然か
- テキストの可読性に問題がないか（モバイルで小さすぎる、デスクトップで間延びしている等）
- 画面間でヘッダー・ナビゲーション等の共通要素が統一されているか
- モバイル時に横スクロールが発生していないか
- ブレークポイント切替時のレイアウト変化が自然か

## Step 3: 自己チェック

スクリーンショットでの視覚的確認に加え、コード面でもセルフチェックする:

- トークンの値が正しく使われているか（ハードコードされた値がないか）
- 画面間で共通要素のスタイルが統一されているか
- デザイン方針に沿っているか
- ダミーデータが現実的か
- インタラクション状態が主要な要素に定義されているか
- フォーカス表示がアクセシブルか（コントラスト比、視認性）
- `<meta name="viewport">` が含まれているか
- メディアクエリがモバイルファースト（`min-width` ベース）で記述されているか
- メディアクエリのブレークポイント値が tokens.md と一致（640 / 768 / 1024 / 1280 / 1536）しているか
- 固定 px 幅の指定が必要最小限になっているか
- タッチターゲットが 44×44px 以上を確保できているか

問題があれば修正してから Phase 4 に進む。
