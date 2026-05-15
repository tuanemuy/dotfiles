# Phase 1: ドラフト提案

## 目的

代表画面を5つの異なるビジュアル方向性でHTMLデザインし、ユーザーに具体的な選択肢を提示する。
言葉で方向性を議論するより、実物を見て選ぶほうが圧倒的に精度が高い。

## Step 1: 方向性の設計

5案の方向性を決める。各案は以下の軸で明確に差別化する:

- **トーン**: ミニマル vs マキシマリスト、フォーマル vs カジュアル、など
- **カラー**: ダーク系 vs ライト系、モノクロ vs カラフル、暖色系 vs 寒色系、など
- **タイポグラフィ**: セリフ vs サンセリフ、大胆 vs 繊細、など
- **レイアウト**: 対称 vs 非対称、密 vs 疎、カード型 vs リスト型、など

各案に簡潔な名前をつける（例: 「Clean Editorial」「Bold Geometric」「Warm Organic」）。

ユーザーから参考サイトやイメージの指定があれば、それをベースに方向性を展開する。

## Step 2: HTMLドラフトの作成

Phase 0 で選定した代表画面それぞれについて、各方向性でHTMLファイルを作成する。
Skill ツールで `/frontend-design` を呼び出す。

出力先: `spec/design/drafts/draft-{番号}-{名前}-{画面名}.html`
例:
- `spec/design/drafts/draft-1-clean-editorial-dashboard.html`
- `spec/design/drafts/draft-1-clean-editorial-detail.html`
- `spec/design/drafts/draft-2-bold-geometric-dashboard.html`

代表画面が1つの場合は画面名を省略してもよい:
- `spec/design/drafts/draft-1-clean-editorial.html`

`/frontend-design` に渡すコンテキスト:
- **デザイン対象**: 代表画面の名前と、`spec/pages/index.md` に記載されたその画面の目的・機能
- **方向性**: Step 1 で設計した方向性の名前・意図・具体的な特徴
- **ユーザーシナリオ**: `spec/scenario/` からこの画面に関連するシナリオの要約（ユーザーがこの画面で何をしようとしているか）
- **出力先パス**: 上記の出力先
- **作成条件**: 下記の条件をすべて伝える

作成条件:
- 1つのHTMLファイルに CSS をインラインで含め、単体でブラウザ表示できるようにする
- ダミーデータを使ってリアルな見た目にする
- **レスポンシブ対応必須**: モバイルファーストで設計し、標準ブレークポイント（`sm: 640px` / `md: 768px` / `lg: 1024px` / `xl: 1280px` / `2xl: 1536px`）を使用する。最低限モバイル（<640px）・タブレット（≥768px）・デスクトップ（≥1024px）の3レンジで破綻なく表示されること。Flexbox/Grid と `clamp()`、流動的な単位（%, vw, fr）、`min()`/`max()` を活用し、固定幅 px のレイアウトは避ける
- 各案の方向性の違いが一目でわかるようにする
- `<meta name="viewport" content="width=device-width, initial-scale=1">` を必ず含める

## Step 3: スクリーンショットの取得

作成したHTMLドラフトをagent-browserで開き、デスクトップとモバイルの両方でスクリーンショットを取得する。
ユーザーが視覚的にドラフトを比較でき、かつレスポンシブ挙動も確認できるようにする。

各ドラフトについて、デスクトップ（1280×800、`xl` ブレークポイント）とモバイル（375×667、`sm` 未満のモバイル幅）の2サイズを取得する:

```bash
# HTMLファイルをブラウザで開く
agent-browser --session design-draft open file:///absolute/path/to/spec/design/drafts/draft-1-clean-editorial.html

# デスクトップ表示でスクリーンショット（xl: 1280px）
agent-browser --session design-draft viewport 1280 800
agent-browser --session design-draft screenshot /tmp/design-screenshots/drafts/draft-1-clean-editorial-desktop.png

# モバイル表示でスクリーンショット（sm 未満: 375px）
agent-browser --session design-draft viewport 375 667
agent-browser --session design-draft screenshot /tmp/design-screenshots/drafts/draft-1-clean-editorial-mobile.png

# セッションを閉じる（次のドラフトに進む前に）
agent-browser --session design-draft close
```

スクリーンショットの保存先: `/tmp/design-screenshots/drafts/`
命名規則: `{ドラフト名}-desktop.png`, `{ドラフト名}-mobile.png`

agent-browser に `viewport` サブコマンドが無い場合は、CLIヘルプで該当する画面サイズ指定オプション（`--width`/`--height`、`--device` など）を確認して同等のことを行う。

ドラフトが複数ある場合、サブエージェントに委譲して並列でスクリーンショットを取得してもよい（最大3並列）。
その場合はセッション名を `design-draft-1`, `design-draft-2` のように分離する。

## Step 4: ユーザーへの提示

スクリーンショットを Read ツールで表示しながら、各ドラフトについて以下を簡潔に説明する:
- 方向性の名前と意図
- 特徴的なデザイン要素

ユーザーに選択を求める。「A案ベースで、B案のカラーを取り入れて」のような組み合わせの要望も受け付ける。

**ユーザーの選択を得るまで次のフェーズに進まない。**
