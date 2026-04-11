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

テストケースごとにサブエージェントを起動する。**1つずつ順番に実行する**のがデフォルト（SKILL.md の実行戦略に従う）。

### サブエージェントへの指示テンプレート

```
あなたは agent-browser を使ってWebアプリケーションのテストを実行するテストエンジニアです。

## 前提
- まずプロジェクトルートの CLAUDE.md を読む

## テスト情報
- テストケース: {TC番号} {テスト名}
- 種別: {正常系/異常系}
- サーバーURL: http://localhost:{port}
- セッション名: verify-tc-{番号}
- スクリーンショット保存先: {output_dir}/screenshots/tc-{番号}/

## シードデータ情報
{seed-data.md の内容から該当するテストデータを抽出して記載}
（例: テスト用アカウント test-user@example.com / password123）

## テスト手順

| # | 操作 | 期待結果 |
|---|---|---|
{テストケースの手順テーブルを転記}

## タイムアウト
- このテストケースの実行制限時間は **3分（180秒）**。
- 各 agent-browser コマンドが20秒以上応答しない場合は、そのステップを FAIL として記録し、次のステップに進む。
- 3分を超過した場合は、残りのステップをすべて SKIP として記録し、セッションを閉じて結果を返す。
- コマンドがハングした場合はリトライせず、即座に FAIL として記録する。

## やること

1. agent-browser でセッションを開始する
   ```bash
   agent-browser --session verify-tc-{番号} open http://localhost:{port}{開始パス}
   ```

2. ページの読み込み完了を待つ
   ```bash
   agent-browser --session verify-tc-{番号} wait --load networkidle
   ```

3. 各ステップを順番に実行する:
   a. snapshot を取得し、操作対象の要素を特定する（ref を使う）
      ```bash
      agent-browser --session verify-tc-{番号} snapshot --max-output 8000
      ```
   b. 操作を実行する（click, fill, select 等）
   c. ページ遷移後は wait コマンドで描画完了を待つ（sleep は使わない）
      ```bash
      agent-browser --session verify-tc-{番号} wait --load networkidle
      ```
   d. screenshot を保存する
      ```bash
      agent-browser --session verify-tc-{番号} screenshot {output_dir}/screenshots/tc-{番号}/step-{NN}.png
      ```
   e. 期待結果を検証する:
      - テキストの表示確認: `find text "期待するテキスト"` または `get text --ref @eN`
      - 要素の表示確認: `is visible @eN`
      - URL の確認: `get url`
      - 要素の状態確認: `is enabled @eN`
      - 待機が必要な場合: `wait --text "期待するテキスト" --timeout 15000`
   f. 検証結果を記録する（PASS / FAIL + 実際の結果）

4. 失敗したステップがあった場合:
   - 失敗時点のスクリーンショットを追加保存する
     ```bash
     agent-browser --session verify-tc-{番号} screenshot {output_dir}/screenshots/tc-{番号}/fail-step-{NN}.png
     ```
   - snapshot も保存し、画面の状態を記録する
   - 以降のステップも可能な限り続行する（1ステップの失敗で全体を中断しない）

5. テスト完了後、セッションを閉じる
   ```bash
   agent-browser --session verify-tc-{番号} close
   ```

## 重要な原則
- テスト手順に忠実に従う — 勝手にステップを省略・変更しない
- 操作対象は必ず snapshot の ref で指定する — セレクタを直書きしない
- 各ステップでスクリーンショットを保存する — レポートの証拠になる
- snapshot の --max-output 8000 を使い、コンテキストを保護する
- 期待結果の判定は厳密に行う — 「だいたい合ってる」は FAIL
- フォーム入力にはシードデータ情報のテストデータを使う
- ページ遷移・操作の後は `wait --load networkidle` を使う（sleep は使わない）
- タイムアウト（3分）を意識し、超過しそうなら残りを SKIP にして結果を返す

## 出力

以下の形式で結果を返すこと:

```markdown
# TC-{番号}: {テスト名}

**結果**: PASS / FAIL / TIMEOUT
**実行時間**: {秒}

## 実行ログ

| # | 操作 | 期待結果 | 実際の結果 | 判定 |
|---|------|---------|-----------|------|
| 1 | {操作} | {期待結果} | {実際} | PASS/FAIL/SKIP |

## スクリーンショット
- Step 1: screenshots/tc-{番号}/step-01.png
- ...

## 失敗詳細（FAIL/TIMEOUTの場合）
- 失敗ステップ: Step {N}
- 期待: {期待結果}
- 実際: {実際の結果}
- 考えられる原因: {分析}
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

## 認証が必要なテストケース

ログインが前提のテストケースでは、テスト開始時にログイン操作を行う:

1. ログインページを開く
2. シードデータのテストアカウントでログインする
3. ログイン成功を確認してからテスト手順を開始する

複数のテストケースでログインが必要な場合、各テストケースで毎回ログインする（セッションを分離しているため）。

## エラーハンドリング

### agent-browser コマンドの失敗

コマンドが失敗した場合:
1. エラーメッセージを記録する
2. snapshot で現在の画面状態を確認する
3. 要素が見つからない場合は代替検索を試みる
4. ページ読み込みが完了していない場合は `wait text` で待機する
5. それでも失敗する場合は、そのステップを FAIL として記録し、可能なら次のステップに進む

### タイムアウト

`wait` コマンドのタイムアウト（デフォルト10秒）を超えた場合:
1. snapshot で画面状態を確認する
2. ページがまだ読み込み中なら、タイムアウトを延長して再試行（最大30秒）
3. ページ読み込みは完了しているが期待するテキストがない場合は FAIL
