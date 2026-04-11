---
name: manual-test
model: sonnet
description: >
  testing.md や spec/manual-tests/ のテスト手順書を agent-browser で自動実行し、
  実装の動作をブラウザ上で検証するスキル。
  Webサーバーの起動（空きポート自動検出）→ シードデータ整備 → テストケース実行 →
  スクリーンショット付き結果レポート → 失敗時は原因分析してGitHub Issueを起票する。
  issue-implement の Phase 2 完了後や implement の Phase 7 完了後に呼ばれることを想定するが、
  単体でも使える。
  ユーザーが「ブラウザで動作確認して」「testing.md を実行して」「マニュアルテスト自動実行して」
  「ブラウザテストして」「画面確認して」「browser verify」「動作検証して」
  「手動テスト自動化して」「テスト手順を実行して」「実装の動作を確認して」
  「agent-browserでテストして」「E2Eで画面確認して」
  などと言ったときにトリガーする。
  testing.md や spec/manual-tests/ が存在する状態で動作確認を求められたら積極的にこのスキルを使うこと。
  issue-implement や implement からの呼び出しにも対応する。
---

# Browser Verify — agent-browser によるテスト手順の自動実行＋修正ループ

testing.md や spec/manual-tests/ に書かれたテスト手順を、agent-browser で実際のブラウザ上で自動実行する。
テスト結果はスクリーンショット付きレポートとして記録し、失敗したテストは原因分析→修正→再テストのループで解消する。

## 前提条件

`agent-browser` CLI が必要。

```bash
agent-browser --version  # 確認
agent-browser install     # Chrome for Testing のセットアップ（初回のみ）
```

## アーキテクチャ

```
メインエージェント（オーケストレーション）
  ├── サブエージェント: seed-data（シードデータ整備）
  └── サブエージェント: verify-{TC番号}（テスト実行）× N
```

メインエージェントはオーケストレーションに集中する。ブラウザ操作・コード修正はサブエージェントに委譲する。

## Workflow Overview

```
Phase 1: 準備
  テストソース特定 → サーバー起動コマンド検出 → agent-browser 確認

Phase 2: シードデータ整備
  テストに必要なデータの準備（DB投入・ファイル配置・環境変数設定等）

Phase 3: サーバー起動
  空きポート検出 → サーバーをバックグラウンド起動 → ヘルスチェック

Phase 4: テスト実行
  テストケースを agent-browser で順番に実行 → スクリーンショット → 結果記録

Phase 5: 失敗分析＆Issue起票
  失敗テストの原因分析 → 分類 → GitHub Issue を起票

Phase 6: レポート＆クリーンアップ
  最終レポート生成 → サーバー停止 → セッションクリーンアップ
```

---

## Phase 1: 準備

### テストソースの特定

以下の優先順で検索し、テストケースのソースを決定する:

1. ユーザーが明示的に指定したファイル
2. `.issue/{Issue番号}/testing.md` — issue-implement から呼ばれた場合
3. `spec/manual-tests/` — implement / manual-test から呼ばれた場合
4. プロジェクトルート直下や docs/ の testing 関連ファイル

テストソースが見つからない場合はユーザーに確認する。

### サーバー起動コマンドの検出

`references/server-detection.md` を読み、その手順に従ってサーバー起動コマンドとポートを検出する。

### agent-browser の確認

```bash
agent-browser --version
```

利用できない場合はユーザーにインストールを案内して中断する。

### タイムアウト設定

agent-browser のデフォルトタイムアウトを設定する。25秒では不足するケース（SPA の初回描画等）があるため、テスト実行前に環境変数を設定する:

```bash
export AGENT_BROWSER_DEFAULT_TIMEOUT=20000   # コマンド単位: 20秒
export AGENT_BROWSER_IDLE_TIMEOUT_MS=120000  # daemon無操作: 2分で自動終了
```

### 成果物ディレクトリの決定

呼び出し元に応じて成果物の保存先を決める:

- issue-implement から: `.issue/{Issue番号}/manual-test/`
- implement から: `.manual-test/`
- 単体実行: `.manual-test/`

以降、この保存先を `{output_dir}` と表記する。

---

## Phase 2: シードデータ整備

ブラウザテストの前に、テストに必要なデータ・環境を整備する。テストケースの前提条件セクションと、プロジェクトのセットアップ手順から必要な準備を特定する。

サブエージェントを起動してシードデータを整備する:

```
あなたはテスト環境のセットアップを行うエンジニアです。

## 前提
- まずプロジェクトルートの CLAUDE.md を読み、プロジェクトの構成を把握する
- README.md のセットアップ手順も確認する

## テストソース
{テストソースのファイルパス}

## やること
1. テストソースを読み、テストケースの前提条件・テストデータを洗い出す
2. 以下の観点でデータ整備が必要か判断する:
   - DB のマイグレーション実行が必要か
   - シードデータ（初期データ）の投入が必要か
   - テスト用のユーザーアカウントや設定が必要か
   - 環境変数やコンフィグファイルの設定が必要か
   - テスト用のファイル（画像、CSV等）の配置が必要か
3. 必要な準備を実行する
   - プロジェクトに seed スクリプトがあればそれを使う
   - なければ手動で投入する（SQL実行、API呼び出し等）
   - .env.example → .env のコピーや環境変数設定
4. 整備後、テストに使うデータの一覧をまとめる

## 重要な原則
- 既存の本番データを上書き・削除しない
- プロジェクトの既存のシード仕組み（seed スクリプト、fixtures 等）を優先的に使う
- テスト用データは明確にテスト用とわかる値にする（test-user@example.com 等）
- 環境変数でテスト環境と判別できる場合は、テスト環境向けの設定を使う

## 出力
- 実行した準備作業の一覧
- 投入したシードデータの概要（テーブル名・レコード数等）
- テストで使用するアカウント情報（ユーザー名・パスワード等）
- 設定した環境変数（値はマスクしてキー名のみ）
- 問題があった場合はその内容と対処
```

シードデータ整備の結果は `{output_dir}/seed-data.md` に記録する。テスト実行時に参照する。

シードデータ整備が不要な場合（静的サイトのテスト等）はスキップする。

---

## Phase 3: サーバー起動

### 空きポート検出

Phase 1 で検出したポートが使用中の場合、空いているポートを探す:

```bash
# ポートが使用中か確認
lsof -i :{port} 2>/dev/null

# 空きポートを探す（検出ポートから順に試す）
for port in {detected_port} {detected_port+1} {detected_port+2} ...; do
  lsof -i :$port 2>/dev/null || echo "Port $port is available"
done
```

### サーバーのバックグラウンド起動

検出したコマンドでサーバーをバックグラウンド起動する。ポートが変わった場合は環境変数やコマンドラインオプションで指定する:

```bash
# 例: Next.js
PORT={port} nohup pnpm dev > /tmp/manual-test-server.log 2>&1 &
SERVER_PID=$!
echo $SERVER_PID > /tmp/manual-test-server.pid
```

### ヘルスチェック

サーバーが応答可能になるまで待つ:

```bash
for i in $(seq 1 30); do
  curl -s -o /dev/null -w "%{http_code}" http://localhost:{port}/ && break
  sleep 2
done
```

30回（60秒）以内に応答がなければ、サーバーログを確認してエラーを報告する。

起動結果（PID、ポート、URL）を `{output_dir}/server-info.md` に記録する。

---

## Phase 4: テスト実行

`references/test-execution.md` を読み、その手順に従ってテストを実行する。

テストケースごとにセッションを分離し、サブエージェントで実行する。

### 実行戦略: 原則として順次実行

テストケースは **1つずつ順番に実行する（順次実行）** のがデフォルト。並列実行はリソース消費・セッション衝突・デバッグ困難の原因になるため、原則として行わない。

並列実行を許容するのは以下の条件を **すべて** 満たす場合のみ:
- テストケースが完全に独立している（前後関係なし、共有リソースなし）
- テストケース数が6つ以上ある
- ユーザーが明示的に「並列でやって」と指示した

並列実行する場合でも **同時実行数は最大2つ** とする。

各テストケースの実行結果は `{output_dir}/results/TC-{番号}.md` に以下の形式で保存する:

```markdown
# TC-{番号}: {テスト名}

**結果**: PASS / FAIL
**実行時間**: {秒}
**セッション**: verify-tc-{番号}

## 実行ログ

| # | 操作 | 期待結果 | 実際の結果 | 判定 |
|---|------|---------|-----------|------|
| 1 | {操作内容} | {期待結果} | {実際に確認できた内容} | PASS/FAIL |
| 2 | ... | ... | ... | ... |

## スクリーンショット

- Step 1: `screenshots/tc-{番号}/step-01.png`
- Step 2: `screenshots/tc-{番号}/step-02.png`
- ...

## 失敗詳細（FAILの場合）

- **失敗ステップ**: Step {N}
- **期待**: {期待結果}
- **実際**: {実際の結果}
- **スクリーンショット**: `screenshots/tc-{番号}/fail-step-{N}.png`
```

全テストケースの実行が完了したら、サマリーを `{output_dir}/results/summary.md` に生成する:

```markdown
# テスト実行サマリー

**実行日時**: {日時}
**テストソース**: {ファイルパス}
**サーバー**: http://localhost:{port}

| TC | テスト名 | 種別 | 結果 | 失敗ステップ |
|----|---------|------|------|-------------|
| TC-001 | {名前} | 正常系 | PASS | - |
| TC-002 | {名前} | 異常系 | FAIL | Step 3 |

**合計**: {数} 件（PASS: {数} / FAIL: {数}）
```

---

## Phase 5: 失敗分析＆Issue起票

FAIL のテストケースがない場合はこの Phase をスキップして Phase 6 へ進む。

### 原因分析

失敗した各テストケースについて:
1. 失敗ステップのスクリーンショットとログを確認する
2. 期待結果と実際の結果の差分を分析する
3. 以下のいずれかに分類する:
   - **実装バグ**: コードが仕様通りに動いていない
   - **テスト手順の問題**: テスト手順や期待結果が現実と合っていない
   - **環境問題**: データ不足・サーバー状態等
   - **デザイン差異**: 機能は動くがUI配置やテキストが異なる

分析結果は `{output_dir}/results/analysis.md` に記録する。

### Issue起票

分類ごとにまとめて GitHub Issue を起票する。1つの失敗が1つのIssueとは限らない — 同じ原因に起因する複数の失敗は1つのIssueにまとめる。

起票前に `gh issue list --search "{キーワード}"` で既存 Issue との重複を確認する。重複がある場合は起票せず、既存 Issue へのコメント追記で対応する。

```bash
gh issue create --title "{タイトル}" --body "$(cat <<'EOF'
## 概要

ブラウザ検証（manual-test）で以下のテストケースが失敗しました。

## 失敗したテストケース

| TC | テスト名 | 失敗ステップ | 分類 |
|----|---------|-------------|------|
| TC-{番号} | {テスト名} | Step {N} | {分類} |

## 再現手順

1. {サーバー起動コマンド}
2. {失敗ステップの操作手順}

## 期待される動作

{期待結果}

## 実際の動作

{実際の結果}

## スクリーンショット

{失敗時のスクリーンショットを添付 or パスを記載}

## 原因分析

{原因分析の結果}

## 関連ファイル

- テストソース: {testing.md or manual-tests のパス}
- テスト結果: {output_dir}/results/TC-{番号}.md
- 検証レポート: {output_dir}/report.md

---
🤖 Generated by manual-test skill
EOF
)" --label "bug"
```

ラベルについて:
- **実装バグ**: `bug` ラベル
- **テスト手順の問題**: `documentation` ラベル
- **デザイン差異**: `design` ラベル（なければ `bug`）
- **環境問題**: `infrastructure` ラベル（なければ `bug`）

ラベルがリポジトリに存在しない場合は `bug` にフォールバックする。

起票した Issue 一覧は `{output_dir}/issues.md` に記録する。

---

## Phase 6: レポート＆クリーンアップ

### 最終レポート生成

`references/report-format.md` を読み、最終レポートを `{output_dir}/report.md` に生成する。

### クリーンアップ

「タイムアウト＆スタック対策」セクションの Phase 6 クリーンアップ手順に従う。

### 完了報告

```
ブラウザ検証が完了しました！

## テスト結果
- テストソース: {ファイルパス}
- サーバー: http://localhost:{port}
- テストケース: {数}件（PASS: {数} / FAIL: {数}）

## 起票したIssue
- {Issue一覧、またはなし}

## 成果物
- レポート: {output_dir}/report.md
- テスト結果: {output_dir}/results/
- スクリーンショット: {output_dir}/screenshots/
- Issue一覧: {output_dir}/issues.md（起票した場合）

{全PASSの場合}
すべてのテストケースがPASSしました。

{FAILがある場合}
失敗したテストケースについて以下のIssueを起票しました:
- #{Issue番号}: {タイトル}（{分類}）
```

---

## セッション管理

サブエージェント間でブラウザが衝突しないよう、必ず `--session` で分離する:

```bash
agent-browser --session verify-tc-001 open http://localhost:{port}
agent-browser --session verify-tc-002 open http://localhost:{port}/login
```

命名規則:
- `verify-tc-{番号}` — テストケース実行
- `headed-verify` — headed モード（デバッグ時）

テスト完了後は必ずセッションを閉じる:

```bash
agent-browser --session verify-tc-001 close
```

## タイムアウト＆スタック対策

テストが無限に止まらないための仕組み。agent-browser は25秒のデフォルトタイムアウトを持つが、テストケース全体・サーバー起動にもガードが必要。

### コマンド単位のタイムアウト

agent-browser の各コマンドは `AGENT_BROWSER_DEFAULT_TIMEOUT`（Phase 1 で設定済み）に従う。個別に長い待機が必要な場合は `wait` コマンドで明示的に待つ:

```bash
# 特定テキストの出現を最大15秒待つ
agent-browser --session {s} wait --text "読み込み完了" --timeout 15000

# ページの描画完了を待つ
agent-browser --session {s} wait --load networkidle
```

### テストケース単位のタイムアウト

サブエージェントに「1テストケースあたり3分（180秒）を超えたら中断してFAILとして記録する」と指示する。サブエージェントへの指示テンプレートに以下を含める:

```
## タイムアウト
- このテストケースの実行制限時間は3分（180秒）。
- 各 agent-browser コマンドが20秒以上応答しない場合は、そのステップを FAIL として記録し、次のステップに進む。
- 3分を超過した場合は、残りのステップをすべて SKIP として記録し、セッションを閉じて結果を返す。
```

### サーバー起動のタイムアウト

Phase 3 のヘルスチェックは60秒（30回×2秒）で十分。追加の安全策として Bash の timeout コマンドを使う:

```bash
timeout 90 bash -c 'for i in $(seq 1 30); do curl -s -o /dev/null -w "%{http_code}" http://localhost:{port}/ | grep -q "200\|301\|302" && exit 0; sleep 2; done; exit 1'
```

### スタック検出＆リカバリー

テスト実行中にサブエージェントが応答しなくなった場合のフォールバック:

1. メインエージェントはサブエージェントの完了を待つが、**5分**を目安に異常と判断する
2. 応答がない場合は `agent-browser close --all` で全セッションを強制終了する
3. そのテストケースを TIMEOUT として記録し、次のテストケースに進む

### Phase 6 での確実なクリーンアップ

個別セッションの close に加え、最後に全セッションを一括クリーンアップする:

```bash
# 全セッションを確実に閉じる
agent-browser close --all 2>/dev/null

# サーバー停止
kill $(cat /tmp/manual-test-server.pid) 2>/dev/null
rm /tmp/manual-test-server.pid /tmp/manual-test-server.log 2>/dev/null
```

## agent-browser コマンドリファレンス

```bash
# ナビゲーション
agent-browser --session {s} open {url}
agent-browser --session {s} back
agent-browser --session {s} reload

# 調査
agent-browser --session {s} snapshot --max-output 8000
agent-browser --session {s} snapshot --ref @e3
agent-browser --session {s} screenshot /path/to/screenshot.png
agent-browser --session {s} get text --ref @e5
agent-browser --session {s} get url
agent-browser --session {s} get title

# 操作
agent-browser --session {s} click @e2
agent-browser --session {s} fill @e3 "test@example.com"
agent-browser --session {s} select @e4 --value "option1"
agent-browser --session {s} check @e5
agent-browser --session {s} press Enter
agent-browser --session {s} scroll down 500
agent-browser --session {s} hover @e6

# バッチ実行（複数コマンドを1回で実行、効率的）
agent-browser --session {s} batch "open {url}" "snapshot -i" "screenshot /path/to/shot.png"
agent-browser --session {s} batch --bail "fill @e1 'test'" "click @e2" "screenshot /path/to/shot.png"  # --bail: エラーで中断

# 待機
agent-browser --session {s} wait 2000                              # ミリ秒待機
agent-browser --session {s} wait --text "読み込み完了" --timeout 15000  # テキスト出現待ち
agent-browser --session {s} wait --load networkidle                # ネットワーク安定待ち
agent-browser --session {s} wait --url "**/dashboard"              # URL パターン待ち

# 要素の発見
agent-browser --session {s} find role "button"
agent-browser --session {s} find text "ログイン"
agent-browser --session {s} find placeholder "メールアドレス"

# 状態確認
agent-browser --session {s} is visible @e3
agent-browser --session {s} is enabled @e4

# セッション管理
agent-browser --session {s} close
agent-browser close --all          # 全セッション一括終了
agent-browser session list         # アクティブセッション一覧
```

ref（@e1, @e2...）は snapshot で取得できる。操作対象は ref で指定するのが基本。

### ページ遷移後の待機

`sleep 1` ではなく `wait` コマンドを使うこと。描画完了の判断がより正確になる:

```bash
# NG: sleep で固定時間待つ
sleep 1

# OK: ネットワークが落ち着くまで待つ
agent-browser --session {s} wait --load networkidle

# OK: 特定要素の出現を待つ
agent-browser --session {s} wait --text "ダッシュボード"
```

---

## 原則

- **テストソースに忠実に実行する** — 手順を勝手に変えたり省略したりしない
- **スクリーンショットは証拠** — 各ステップ・特に失敗時は必ず撮影し、レポートから参照できるようにする
- **サーバーは必ず停止する** — テスト終了後（成功・失敗問わず）サーバーを停止し、ポートを解放する
- **コードは修正しない** — 失敗を検出したら原因分析とIssue起票に留め、修正は別のIssue対応フローに委ねる
- **Issue は重複起票しない** — 起票前に既存 Issue を検索し、同じ原因の失敗はまとめて1つのIssueにする
- **環境を汚さない** — テストで作成したデータ・ファイルは記録し、必要なら後始末する
- **セッションは分離する** — テストケースごとに別セッションを使い、状態の干渉を防ぐ
- **サブエージェントには必ずプロジェクトルートの CLAUDE.md を最初に読むよう指示する**
- **snapshot の出力制限** — `--max-output 8000` を使い、コンテキストウィンドウを保護する
- **ページ遷移後は wait コマンドで待機** — `sleep` ではなく `wait --load networkidle` や `wait --text` を使う
- **順次実行がデフォルト** — テストケースは1つずつ実行。並列は明示指示があるときだけ、最大2つまで
- **タイムアウトを必ず設定する** — テストケースは3分、コマンドは20秒を上限とし、超過したら FAIL/SKIP として記録
