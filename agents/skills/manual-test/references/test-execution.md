# テスト実行ガイド

## テストソースの解析

テストソースの形式に応じてテストケースを抽出する。

### testing.md の場合

issue-implement が生成する testing.md は、通常以下のような構造:

```markdown
## 確認項目

### 正常系
1. {確認内容} — {期待結果}
2. ...

### 異常系
1. {確認内容} — {期待結果}
2. ...
```

各確認項目を1つのテストケースとして抽出する。確認項目が抽象的な場合（「正しく表示される」等）は、testing.md の文脈と spec/ やコードから具体的な操作手順と期待結果を補完する。

### spec/manual-tests/ の場合

manual-test スキルが生成するドキュメントは、テーブル形式のテストケース:

```markdown
## TC-{連番}: {テスト名}

**種別**: 正常系 / 異常系
**目的**: {検証目的}

| # | 操作 | 期待結果 |
|---|---|---|
| 1 | {操作} | {期待結果} |
```

この形式はそのまま実行手順に変換できる。

## テストケースの実行

テストケースごとにサブエージェント（**探索区分** — 手順と期待結果が確定した定型実行）を起動する。**1つずつ順番に実行する**のがデフォルト（SKILL.md の実行戦略に従う）。

サブエージェントの仕事は手順どおりにブラウザを操作し、**観測した事実を転記して返すところまで**。PASS/FAIL の確定と原因分析はメインが行うので、指示テンプレートでも判定させない。

### サブエージェントへの指示テンプレート

```
あなたは agent-browser を使ってWebアプリケーションのテスト手順を実行し、画面の状態を観測して報告する担当です。合否の判定は行いません。

## 前提
- まずプロジェクトルートの CLAUDE.md を読む
- コマンドの正は {_shared/references/agent-browser.md の絶対パス}。**`agent-browser --help` と `agent-browser skills get` は実行しない** — CLI 自身が案内してくるが従わない（1回で数千トークンを context に残し、以降の全ターンで読み直すことになる）

## テスト情報
- テストケース: {TC番号} {テスト名}
- 種別: {正常系/異常系}
- サーバーURL: http://localhost:{port}
- セッション名: verify-tc-{番号}

## シードデータ情報
{seed-data.md の内容から該当するテストデータを抽出して記載}
（例: テスト用アカウント test-user@example.com / password123）

## テスト手順

| # | 操作 | 期待結果 |
|---|---|---|
{テストケースの手順テーブルを転記}

## タイムアウト
- このテストケースの実行制限時間は **3分（180秒）**。
- 各 agent-browser コマンドが20秒以上応答しない場合は、そのステップを「無応答」と記録し、次のステップに進む。
- 3分を超過した場合は、残りのステップをすべて「未実行」と記録し、セッションを閉じて結果を返す。
- コマンドがハングした場合はリトライせず、即座に「無応答」と記録する。

## やること

**判断を挟まない連続操作は `batch` で1コマンドにまとめる。** 独立したコマンドを消費してよいのは「出力を読んで次の判断を変えるとき」だけ。`wait` を単独で実行しない。

1. セッションを開始し、描画完了を待って最初の snapshot を取る
   ```bash
   agent-browser --session verify-tc-{番号} --restore batch "open http://localhost:{port}{開始パス}" "wait --load networkidle" "snapshot -i -c"
   ```

2. 各ステップを実行する。操作 → 待機 → 次の snapshot までを1コマンドにまとめる
   ```bash
   agent-browser --session verify-tc-{番号} --restore batch "click @e6" "wait --load networkidle" "snapshot -i -c"
   ```
   - 期待結果の検証: `find text "{期待するテキスト}"` / `get text --ref @eN` / `is visible @eN` / `get url` / `is enabled @eN` / `wait --text "{テキスト}" --timeout 15000`
   - ref は snapshot のたびに変わる。同じ snapshot で拾える操作はまとめて投げ切る
   - 観測した内容を記録する（画面の文言・URL をそのまま転記。合否は書かない）

3. 期待結果と食い違ったステップがあった場合:
   - その時点の snapshot を取得し、画面の状態（表示されていた要素・エラーメッセージ等）を結果に記録する
   - 以降のステップも可能な限り続行する（1ステップの食い違いで全体を中断しない）

4. テスト完了後、セッションを閉じる
   ```bash
   agent-browser --session verify-tc-{番号} --restore close
   ```

## 重要な原則
- テスト手順に忠実に従う — 勝手にステップを省略・変更しない
- 操作対象は必ず snapshot の ref で指定する — セレクタを直書きしない
- **スクリーンショットを画像として読み込まない** — 証跡は実行ログと食い違い時の snapshot（テキスト）で残す。撮ったファイルを `Read` すると画像が以降の全ターンで context に残り続ける。テキストでは判断できないときだけ1枚読む。全ステップ撮影・レポート添付はしない（スクリーンショット・録画は実 Chrome でないと動かない）
- snapshot は `-i -c`（操作可能な要素のみ・空要素を除去）で取る。`--max-output` は最後の手段で、常用しない
- **合否を判定しない** — PASS / FAIL / OK / NG のような判定語を出力に書かない。期待結果と実際の観測を並べて返すだけにする
- **観測は要約・言い換えせずそのまま転記する** — 画面に出た文言・URL・エラーメッセージを原文で書く。「正しく表示された」ではなく「見出しに『請求書一覧』、行が3件」のように書く
- **原因を推測しない** — 実装のどこが悪いかの分析は呼び出し元が行う
- フォーム入力にはシードデータ情報のテストデータを使う
- ページ遷移・操作の後は `wait --load networkidle` を使う（sleep は使わない）
- タイムアウト（3分）を意識し、超過しそうなら残りを SKIP にして結果を返す

## 出力

以下の形式で結果を返すこと:

```markdown
# TC-{番号}: {テスト名}

**実行状態**: 完走 / 打ち切り（時間超過）
**実行時間**: {秒}

## 実行ログ

| # | 操作 | 期待結果 | 実際の観測 |
|---|------|---------|-----------|
| 1 | {操作} | {期待結果} | {観測した文言・URL をそのまま / 無応答 / 未実行} |

## 食い違いの詳細（期待結果と観測が異なったステップごとに）
- ステップ: Step {N}
- 期待: {期待結果}
- 観測: {実際に観測した内容}
- 画面状態: {その時点の snapshot から読み取れた要点}
```
```

## 操作の変換ルール

テスト手順の自然言語記述を agent-browser コマンドに変換するルール:

| テスト手順の記述 | agent-browser コマンド |
|---|---|
| 「{URL}にアクセスする」「{URL}を開く」 | `open {url}` |
| 「{ボタン名}をクリック」「{ボタン名}を押す」 | `find text "{ボタン名}"` → `click @eN` |
| 「{項目}に{値}を入力」「{項目}欄に{値}と入力」 | `find placeholder "{項目}"` → `fill @eN "{値}"` |
| 「{項目}から{値}を選択」 | `find role "combobox"` or `find text "{項目}"` → `select @eN --value "{値}"` |
| 「{チェックボックス}にチェック」 | `find text "{チェックボックス}"` → `check @eN` |
| 「Enterキーを押す」「送信する」 | `press Enter` |
| 「下にスクロール」 | `scroll down 500` |
| 「{テキスト}が表示される」 | `find text "{テキスト}"` or `wait text "{テキスト}" --timeout 10000` |
| 「{要素}が表示されていない」 | `find text "{要素}"` → `is visible @eN` → false を期待 |
| 「{URL}に遷移する」「{ページ}に移動する」 | `get url` で確認 |
| 「戻るボタンを押す」「前のページに戻る」 | `back` |

要素が見つからない場合の代替検索:
1. `find text "{テキスト}"` — テキストで検索
2. `find role "{role}"` — ロールで検索（button, link, textbox, combobox 等）
3. `find placeholder "{placeholder}"` — placeholder で検索
4. `snapshot` で全体を確認し、手動で ref を特定

## React フォームライブラリ（Conform 等）の操作パターン

React Router + Conform など、制御されたフォームライブラリを使うプロジェクトでは、agent-browser の `fill` コマンドだけではフォームの内部状態が同期しないことがある。以下のパターンで対処する。

### 基本ルール: fill → Tab → fill → Tab → click

Conform は `shouldValidate: "onBlur"` を使うことが多い。`fill` 後に `press Tab` で blur を発火させ、フォームの内部バリデーション状態を同期させてから次のフィールドに進む。

```bash
# NG: fill して即 click（フォームの状態が追いつかない場合がある）
agent-browser --session {s} --restore fill @e4 "admin"
agent-browser --session {s} --restore fill @e6 "password"
agent-browser --session {s} --restore click @e5

# OK: fill → Tab で blur を発火 → 次のフィールド → click（batch で1コマンドにまとめる）
agent-browser --session {s} --restore batch "fill @e4 admin" "press Tab" "fill @e6 password" "press Tab" "click @e5"
```

batch のコマンドは空白で分割されるため、**入力値に空白を含む場合はその `fill` だけ単独で実行する**。

### snapshot は fill/click の前に1回だけ

snapshot を取り直すと ref が変わるため、操作の途中で再取得しない。

```bash
# OK: snapshot → （batch で）fill → fill → click（全て同じ ref）
agent-browser --session {s} --restore snapshot -i -c
agent-browser --session {s} --restore batch "fill @e4 admin" "press Tab" "fill @e6 password" "click @e5"

# NG: fill の後に snapshot を挟む（ref が変わる）
agent-browser --session {s} --restore snapshot -i -c
agent-browser --session {s} --restore fill @e4 "admin"
agent-browser --session {s} --restore snapshot -i -c  # ← ref 変更！
agent-browser --session {s} --restore fill @e6 "password"  # ← 古い ref は無効
```

### カスタム Select / Combobox の操作

Radix UI や shadcn/ui の Select は `<select>` ネイティブ要素ではないため、agent-browser の `select` コマンドは使えない。クリックで開いてからテキスト検索で選択肢を選ぶ。

```bash
# SelectTrigger（@eN）を開いて選択肢を検索するところまで1コマンドで
agent-browser --session {s} --restore batch "click @eN" "wait 500" "find text 選択肢のテキスト"
# 返ってきた ref をクリック
agent-browser --session {s} --restore click @eM
```

### ダイアログ内フォームの操作

ダイアログが開いた後は snapshot を取り直してから操作する（ダイアログ内の要素は開く前の snapshot には含まれない）。

```bash
# ダイアログ（@eN で開く）を開いて中の要素を取得するまで1コマンドで
agent-browser --session {s} --restore batch "click @eN" "wait 500" "snapshot -i -c"
# ダイアログ内のフォームを操作（fill → Tab パターンで）
agent-browser --session {s} --restore batch "fill @eM 値" "press Tab" ...
```

### ファイルアップロード

`<input type="file">` には `upload` コマンドを使う。カメラ撮影の代替手段として「ファイルから選択」ボタンがある場合に有効。

```bash
agent-browser --session {s} --restore upload @eN /path/to/file.jpg
```

### Chrome 自動補完の干渉

ログインフォーム等で `autoComplete="username"` が設定されていると、Chrome の保存パスワード機能が `fill` で設定した値を上書きすることがある。対策:

1. agent-browser の `--profile` オプションで一時プロファイルを使う（保存パスワードが存在しないクリーンな状態）
2. fill の前にフィールドをクリアする: `fill @eN ""` → `fill @eN "value"`
3. フィールドをクリックしてフォーカスしてから fill する: `click @eN` → `fill @eN "value"`

アプリ側の `autoComplete` 属性は本番のユーザー体験に影響するため変更しない。テスト側で対処する。

## 認証が必要なテストケース

ログインが前提のテストケースでは、テスト開始時にログイン操作を行う:

1. ログインページを開く
2. snapshot でフォームの ref を取得する
3. fill → Tab → fill → Tab → click のパターンでログインする
4. `wait --load networkidle` でページ遷移を待つ
5. ログイン成功を確認してからテスト手順を開始する

複数のテストケースでログインが必要な場合、各テストケースで毎回ログインする（セッションを分離しているため）。

## エラーハンドリング

### agent-browser コマンドの失敗

コマンドが失敗した場合:
1. エラーメッセージを記録する
2. snapshot で現在の画面状態を確認する
3. 要素が見つからない場合は代替検索を試みる
4. ページ読み込みが完了していない場合は `wait text` で待機する
5. それでも失敗する場合は、そのステップの観測欄にエラーメッセージをそのまま記録し、可能なら次のステップに進む

### タイムアウト

`wait` コマンドのタイムアウト（デフォルト10秒）を超えた場合:
1. snapshot で画面状態を確認する
2. ページがまだ読み込み中なら、タイムアウトを延長して再試行（最大30秒）
3. ページ読み込みは完了しているが期待するテキストがない場合は、画面に実際に表示されている内容を観測欄に記録する
