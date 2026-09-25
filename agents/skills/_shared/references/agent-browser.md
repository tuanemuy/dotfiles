# agent-browser 利用リファレンス

ブラウザ操作を伴うスキルは、コマンドの調べ方をここに集約する。

## ドキュメントを実行時に取得しない

`agent-browser --help` と `agent-browser skills get ...` を**実行しない**。CLI 自身が「AI エージェントはまず `skills get core --full` を実行せよ」と案内するが、それに従わない。1回あたり数千トークンをコンテキストに載せ、以降の全ターンで読み直すことになる。

必要な情報は本ファイルにある。ここに無いコマンドが必要になったときだけ `--help` を1回実行し、**使ったコマンドを本ファイルに追記する**。

## 1ターンに1コマンドを避ける

**独立した LLM ターンを消費してよいのは「出力を読んで次の判断を変えるとき」だけ**。

判断を挟まない連続操作は `batch` でまとめる:

```bash
agent-browser --namespace {ns} --session s1 --restore batch "open http://localhost:5173/items" "wait --load networkidle" "snapshot -i -c"
```

- `--bail` を付けると最初のエラーで停止する（既定は最後まで実行）
- 短い連結なら `&&` でもよい: `click e6 && wait --load networkidle`

特に **`wait` を単独のターンにしない**。必ず直前の操作と同じ呼び出しに含める。

## 出力量を絞る

`snapshot` の出力はコンテキストに残り、以降の全ターンで再読み込みされる。既定で絞る:

```bash
agent-browser --namespace {ns} --session s1 --restore snapshot -i -c        # 操作可能な要素のみ・空要素を除去
agent-browser --namespace {ns} --session s1 --restore snapshot -s "main"    # 特定領域だけ
```

`--max-output <chars>` は最後の手段。大きい値（8000 など）を常用しない。

## 実行ごとに namespace を分ける

`--namespace` は daemon のソケットと `--restore` の保存先を分ける。namespace が違えば同じセッション名でも別のブラウザになり、`close --all` も自分の namespace のセッションしか閉じない。並列に動く別のスキル実行・別の worktree のブラウザに触れないよう、**全コマンドに `--namespace {ns}` を付ける**。

ブラウザ作業全体を束ねる側（スキルのメイン）が開始時に 1 回だけ決める:

```bash
agent-browser session id --scope worktree --prefix {スキル名}   # 例: manual-test-f91e1e42b5dd
```

- 同じ worktree・同じスキルなら毎回同じ値になる。前回の実行が落ちて残したセッションも、次の開始時に片付く
- worktree が違えば値も違うので、並列実装どうしは干渉しない。同じ worktree で同じスキルを並列に動かすときは `--prefix` に区別する語を足す
- 出力された値をコマンドにそのまま書く。Bash の環境変数は呼び出しをまたいで残らないので、`AGENT_BROWSER_NAMESPACE` に頼らない
- 委譲先には namespace とセッション名をセットで渡す

## セッションは `--restore` とセットで指定する

ブラウザ本体は daemon が握っていて、ページのクラッシュ・アイドルタイムアウト・`close` で再起動する。このとき **`--restore` を付けていないセッションは Cookie と localStorage を捨てる**。ログイン状態で作業していると、操作の合間に突然ログイン画面へ戻される。

```bash
agent-browser --namespace {ns} --session {s} --restore open http://localhost:5173
```

- `--restore` は値を省略すると `--session` の名前を保存キーに使う
- 保存はブラウザを閉じるときと、開いている間の定期保存（既定30秒間隔）で行われる
- 復元失敗時に既知の良い状態を上書きしないよう、保存ポリシーは既定の `auto` のままにする
- `file://` のローカル HTML を見るだけの用途（design-flow 等）では不要

Issue #960 の実測: 同一セッションに httpOnly Cookie を入れて `close` → 再 `open` すると、`--restore` 無しは `cookies: []`、有りは `restoreStatus: "loaded"` で Cookie が残る。この取りこぼしで、過去のブラウザ検証では 54 分間に 17 回の再ログインが発生していた。

## 頻出コマンド

分離は `--namespace {ns} --session <name> --restore`。並行作業ではセッション名を必ず分ける。

| 目的 | コマンド |
| --- | --- |
| 移動 | `open <url>` / `back` / `reload` |
| 構造把握 | `snapshot -i -c`（AI 向け・ref 付き） |
| 本文取得 | `read` / `get text <sel>` |
| 操作 | `click <sel\|@ref>` / `fill <sel> <text>` / `press <key>` / `select <sel> <val>` / `hover <sel>`（ホバーのみ・クリックしない） |
| 待機 | `wait <sel\|ms>` / `wait --load networkidle` |
| 検索 | `find role\|text\|label\|testid <value> <action>` |
| 状態確認 | `is visible\|enabled\|checked <sel>` |
| 画像・録画 | `screenshot [path]` / `record start <path.webm>` / `record stop`（下の「スクリーンショットと録画」） |
| エラー確認 | `console` / `errors` |
| 任意 JS | `eval <js>` |
| ダウンロード | `download <sel\|@ref> <保存パス>`（要素をクリックしてファイルを保存する） |
| ファイル選択 | `upload <sel\|@ref> <パス...>`（`input[type=file]` にファイルを渡す。`fill` では `files` が空のままで反映されない） |
| 終了 | `close` / `close --all` |
| ビューポート変更 | `set viewport <w> <h>`（既定は 1280x633。ポップオーバーが画面外にはみ出すときに使う） |
| タブ管理 | `tab new` / `tab list` / `tab <n>`（切替） / `tab close`。同一セッション内で Cookie を共有した複数タブを扱える（別セッションは Cookie を共有しないため、同一ブラウザーの「別タブ」を再現するにはこちらを使う） |
| 座標クリック | `mouse move <x> <y>` → `mouse down` → `mouse up`（`click`/`find` で拾えない要素の最後の手段） |

`batch` に渡すコマンドは**空白で分割される**。`click table thead th:nth-child(4)` は先頭の `table` だけがセレクタとして解釈され、意図しない要素をクリックする。空白を含む CSS セレクタは避け、`th:nth-child(4)` のように単一トークンで指定する。

`snapshot` が返す `@ref`（`e6` など）はセレクタとして使える。CSS セレクタを組み立てるより安定する。ただし **`download` / `eval` / ポップオーバーの開閉を挟むと ref が振り直される**ことがある（`✗ Unknown ref: e13`）。操作のたびに `snapshot` を取り直すのが安全。

## ファイルをダウンロードする

`click` でダウンロードのトリガーを押しても、ファイルはどこにも残らない（`~/Downloads` にも `AGENT_BROWSER_DOWNLOAD_PATH` にも現れない）。**`download <ref> <保存パス>` を使う。**

```bash
agent-browser --namespace {ns} --session s1 --restore download e13 /path/to/out.pdf
```

保存パスを自分で決めるので、**画面から降ってきたファイル名は失われる。** 元の名前が必要なら、押す前に `<a download>` を差し込みで捕まえる:

```bash
agent-browser --namespace {ns} --session s1 --restore eval "(()=>{if(!window.__dlPatched){window.__dlPatched=1;const o=HTMLAnchorElement.prototype.click;HTMLAnchorElement.prototype.click=function(){if(this.download)window.__dl.push(this.download);return o.apply(this,arguments)};}window.__dl=[];return 'ok'})()"
agent-browser --namespace {ns} --session s1 --restore download e13 /tmp/dl.bin
agent-browser --namespace {ns} --session s1 --restore eval "window.__dl[window.__dl.length-1]"   # → "settlement_statement_20260819_20260819003.pdf"
```

`--download-path <path>`（環境変数 `AGENT_BROWSER_DOWNLOAD_PATH`）もあるが、daemon が起動済みの状態で環境変数を足しても効かなかった。

## 作業ファイルの置き場所

確認用のスクリーンショット・ブラウザプロファイル・サーバーログ / pid は `{scratchpad}` に置く（定義は `scratchpad.md`）。成果物として残す証跡は呼び出し元が指定するディレクトリに置く。

## スクリーンショットと録画

headless の Chrome for Testing で `screenshot` と `record` は動く（agent-browser 0.36.0）。`batch` の中でも使える。PNG は 1280x633 で保存される。

| 目的 | コマンド |
| --- | --- |
| 画面を保存 | `screenshot <path.png>`（`--full` でページ全体） |
| 録画開始 | `record start <path.webm>`（現在のページから開始。Cookie・localStorage は引き継ぐ） |
| 録画停止・保存 | `record stop` |

```bash
agent-browser --namespace {ns} --session {s} --restore batch "open {url}" "record start {dir}/TC-01.webm" "wait --load networkidle" "snapshot -i -c"
agent-browser --namespace {ns} --session {s} --restore batch "click @e2" "wait --load networkidle" "get url" "screenshot {dir}/TC-01.png" "record stop" "close"
```

- `record start` は新しいブラウザコンテキストを作る。**セッションを開いた直後、ログインより前に始める**と、切り替えの影響を受けない
- 撮ったファイルを `Read` で画像として読み込まない。画像は以降の全ターンで context に残る。判断は snapshot（テキスト）で行い、メディアは人が後から見る証跡として残す
- 証跡は `gh pr edit` / `gh issue create` の `--attach <file>` で GitHub にアップロードする（gh 2.99.0 以上）。本文中の `![alt](<file>)` はアップロード先の URL に書き換わる。参照されていない添付は本文末尾に付く。動画はプレイヤーとして表示される
- アップロードはファイル単位で一過性の `HTTP 500`（`Error saving asset` など）を返すことがある。gh は失敗したファイルで止まり、それより前のファイルだけが本文に反映される（先頭で失敗すると `the pull request was not changed`）。同じファイルをもう一度渡せば通る。1 回に載せるのは数ファイルにとどめ、失敗したら `gh pr view --json body -q .body` で本文を取り直し、参照がローカルパスのまま残っているファイルから続ける。出力を `tail` で切ると失敗行が隠れる
- ワークツリーに隔離されたセッションは、実行時に組み立てた値（配列・ループ変数・`find` の結果）を gh に渡すコマンドを拒否する。`--attach` のパスはリテラルで並べる
- 上限は画像 10 MB、動画 10 MB（有料プランは 100 MB）、1 回 50 ファイル。録画は遷移・スクロールが続く画面で約 1.6 MB/分、静止画面で約 0.6 MB/分になる。3 分のテストケースで 5 MB 程度に収まる

## セットアップと後片付け

```bash
agent-browser --version    # 利用可能か確認
agent-browser install      # Chrome for Testing のセットアップ（初回のみ）
```

```bash
agent-browser --namespace {ns} close --all   # 自分の namespace のセッションだけ閉じる
```

- 束ねる側が、作業全体の開始前（前回の取り残し）と終了時に 1 回ずつ実行する。委譲先の後片付けは自分のセッションの `close` だけ
- namespace なしの `close --all` と `pkill -f agent-browser` は使わない。並列に動いている他の実行のブラウザまで止める

## Cookie を読む・書き換える

`document.cookie` は `HttpOnly` Cookie を返さないので、`eval` では読めない。専用サブコマンドを使う。

```bash
agent-browser --namespace {ns} --session {s} --restore cookies get --json          # HttpOnly も含めて全 Cookie を取得
agent-browser --namespace {ns} --session {s} --restore cookies set <name> <value>  # 現在のページ URL に対して設定
agent-browser --namespace {ns} --session {s} --restore cookies clear               # 全消去
```

`cookies set` のオプション: `--url` / `--domain` / `--path` / `--httpOnly` / `--secure` / `--sameSite <Strict|Lax|None>` / `--expires <Unix秒>`。`--url` / `--domain` / `--path` をすべて省略すると現在のページ URL に対して設定される。

**上書きは属性ごと置き換わる。** 元と同じ属性（`--httpOnly --sameSite Lax --path /` など）を明示しないと、値だけ差し替えたつもりで `HttpOnly` が外れる。改ざん再現のテストでは、書き換え前に `cookies get --json` で属性を控えてから同じ属性を付けて `set` する。

## リクエスト・レスポンスヘッダーを読む

DevTools の Network タブに相当する。`Set-Cookie` の生ヘッダーを読むときはこれ。

```bash
agent-browser --namespace {ns} --session {s} --restore network requests --filter "callback" --json
agent-browser --namespace {ns} --session {s} --restore network requests --type document,fetch --method POST
agent-browser --namespace {ns} --session {s} --restore network request <requestId>   # ヘッダー・ボディまで含む詳細
agent-browser --namespace {ns} --session {s} --restore network requests --clear      # 記録をクリア（計測区間を絞る）
```

`requests` は一覧（id・URL・status）を返し、`request <id>` が1件の全詳細を返す。**ヘッダーが要るときだけ `request <id>` を引く** — 一覧を `--json` で丸ごと出すとコンテキストを食う。

## 通信失敗を再現する（DevTools のオフラインの代わり）

DevTools の Network タブは開けないので、`network route` で特定の通信だけを落とす。

```bash
agent-browser --namespace {ns} --session {s} --restore network route "**/_serverFn/**" --abort   # 該当リクエストを中断
agent-browser --namespace {ns} --session {s} --restore network unroute                            # 解除（URL を渡すと個別解除）
```

`--body <json>` を付ければ任意のレスポンスを返せる。オフライン全体をエミュレートするより、**失敗させたい経路だけ `--abort` する**ほうが観測が絞れる。

## React の制御コンポーネントに値を入れる

- `fill <sel> <text>` は React の `onChange` まで届く（Playwright の `Input.insertText` 相当）。長文の貼り付けにも使える。
- `eval` で `value` を直接代入したり `document.execCommand('insertText')` を呼んでも **React の state は更新されない**（DOM の値だけが変わる）。判定に使ってはいけない。
- `type <sel> <text>` はセレクタ引数が必須。`type "<text>"` は `✓ Done` を返すが値が入らない。
- **`<input type="date">` には `fill` も `type` も入らない。** `snapshot -i -c` に出る年 / 月 / 日の `spinbutton` の ref をクリックし、`press 2` `press 0` … と数字キーを1つずつ送る。送出が速いと桁を取りこぼすので、値を `eval` で確認してから次へ進む。
