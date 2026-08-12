# agent-browser 利用リファレンス

ブラウザ操作を伴うスキルは、コマンドの調べ方をここに集約する。

## ドキュメントを実行時に取得しない

`agent-browser --help` と `agent-browser skills get ...` を**実行しない**。CLI 自身が「AI エージェントはまず `skills get core --full` を実行せよ」と案内するが、それに従わない。1回あたり数千トークンをコンテキストに載せ、以降の全ターンで読み直すことになる。

必要な情報は本ファイルにある。ここに無いコマンドが必要になったときだけ `--help` を1回実行し、**使ったコマンドを本ファイルに追記する**。

## 1ターンに1コマンドを避ける

ブラウザ操作はターン数がそのままコストになる。**独立した LLM ターンを消費してよいのは「出力を読んで次の判断を変えるとき」だけ**。

判断を挟まない連続操作は `batch` でまとめる:

```bash
agent-browser --session s1 --restore batch "open http://localhost:5173/items" "wait --load networkidle" "snapshot -i -c"
```

- `--bail` を付けると最初のエラーで停止する（既定は最後まで実行）
- 短い連結なら `&&` でもよい: `click e6 && wait --load networkidle`

特に **`wait` を単独のターンにしない**。必ず直前の操作と同じ呼び出しに含める。

## 出力量を絞る

`snapshot` の出力はコンテキストに残り、以降の全ターンで再読み込みされる。既定で絞る:

```bash
agent-browser --session s1 --restore snapshot -i -c        # 操作可能な要素のみ・空要素を除去
agent-browser --session s1 --restore snapshot -s "main"    # 特定領域だけ
```

`--max-output <chars>` は最後の手段。大きい値（8000 など）を常用しない。

## セッションは `--restore` とセットで指定する

ブラウザ本体は daemon が握っていて、ページのクラッシュ・アイドルタイムアウト・`close` で再起動する。このとき **`--restore` を付けていないセッションは Cookie と localStorage を捨てる**。ログイン状態で作業していると、操作の合間に突然ログイン画面へ戻される。

```bash
agent-browser --session {s} --restore open http://localhost:5173
```

- `--restore` は値を省略すると `--session` の名前を保存キーに使う
- 保存はブラウザを閉じるときと、開いている間の定期保存（既定30秒間隔）で行われる
- 復元失敗時に既知の良い状態を上書きしないよう、保存ポリシーは既定の `auto` のままにする
- `file://` のローカル HTML を見るだけの用途（design-flow 等）では不要

Issue #960 の実測: 同一セッションに httpOnly Cookie を入れて `close` → 再 `open` すると、`--restore` 無しは `cookies: []`、有りは `restoreStatus: "loaded"` で Cookie が残る。この取りこぼしで、過去のブラウザ検証では 54 分間に 17 回の再ログインが発生していた。

## 頻出コマンド

セッション分離は `--session <name> --restore`。並行作業では必ず分ける。

| 目的 | コマンド |
| --- | --- |
| 移動 | `open <url>` / `back` / `reload` |
| 構造把握 | `snapshot -i -c`（AI 向け・ref 付き） |
| 本文取得 | `read` / `get text <sel>` |
| 操作 | `click <sel\|@ref>` / `fill <sel> <text>` / `press <key>` / `select <sel> <val>` |
| 待機 | `wait <sel\|ms>` / `wait --load networkidle` |
| 検索 | `find role\|text\|label\|testid <value> <action>` |
| 状態確認 | `is visible\|enabled\|checked <sel>` |
| 画像 | `screenshot [path]` |
| エラー確認 | `console` / `errors` |
| 任意 JS | `eval <js>` |
| 終了 | `close` / `close --all` |
| ビューポート変更 | `set viewport <w> <h>`（既定は 1280x633。ポップオーバーが画面外にはみ出すときに使う） |
| 座標クリック | `mouse move <x> <y>` → `mouse down` → `mouse up`（`click`/`find` で拾えない要素の最後の手段） |

`batch` に渡すコマンドは**空白で分割される**。`click table thead th:nth-child(4)` は先頭の `table` だけがセレクタとして解釈され、意図しない要素をクリックする。空白を含む CSS セレクタは避け、`th:nth-child(4)` のように単一トークンで指定する。

`snapshot` が返す `@ref`（`e6` など）はセレクタとして使える。CSS セレクタを組み立てるより安定する。

## セットアップと後片付け

```bash
agent-browser --version    # 利用可能か確認
agent-browser install      # Chrome for Testing のセットアップ（初回のみ）
```

開始前と終了時に `/agent-browser-cleanup` を Skill ツールで呼ぶ。
