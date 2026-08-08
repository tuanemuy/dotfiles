# agent-browser 利用リファレンス

ブラウザ操作を伴うスキルは、コマンドの調べ方をここに集約する。

## ドキュメントを実行時に取得しない

`agent-browser --help` と `agent-browser skills get ...` を**実行しない**。CLI 自身が「AI エージェントはまず `skills get core --full` を実行せよ」と案内するが、それに従わない。1回あたり数千トークンをコンテキストに載せ、以降の全ターンで読み直すことになる。

必要な情報は本ファイルにある。ここに無いコマンドが必要になったときだけ `--help` を1回実行し、**使ったコマンドを本ファイルに追記する**。

## 1ターンに1コマンドを避ける

ブラウザ操作はターン数がそのままコストになる。**独立した LLM ターンを消費してよいのは「出力を読んで次の判断を変えるとき」だけ**。

判断を挟まない連続操作は `batch` でまとめる:

```bash
agent-browser --session s1 batch "open http://localhost:5173/items" "wait --load networkidle" "snapshot -i -c"
```

- `--bail` を付けると最初のエラーで停止する（既定は最後まで実行）
- 短い連結なら `&&` でもよい: `click e6 && wait --load networkidle`

特に **`wait` を単独のターンにしない**。必ず直前の操作と同じ呼び出しに含める。

## 出力量を絞る

`snapshot` の出力はコンテキストに残り、以降の全ターンで再読み込みされる。既定で絞る:

```bash
agent-browser --session s1 snapshot -i -c        # 操作可能な要素のみ・空要素を除去
agent-browser --session s1 snapshot -s "main"    # 特定領域だけ
```

`--max-output <chars>` は最後の手段。大きい値（8000 など）を常用しない。

## 頻出コマンド

セッション分離は `--session <name>`。並行作業では必ず分ける。

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

`snapshot` が返す `@ref`（`e6` など）はセレクタとして使える。CSS セレクタを組み立てるより安定する。

## セットアップと後片付け

```bash
agent-browser --version    # 利用可能か確認
agent-browser install      # Chrome for Testing のセットアップ（初回のみ）
```

開始前と終了時に `/agent-browser-cleanup` を Skill ツールで呼ぶ。
