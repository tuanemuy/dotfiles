---
name: web-spec-explorer
description: >
  agent-browserでWebサービスを実際に操作しながら、仕様（画面構成、ユーザーフロー、入力項目、
  状態遷移、認証、共通コンポーネント等）を洗い出し、spec/ディレクトリにMarkdownで構造化出力するスキル。
  メインエージェントはオーケストレーションに専念し、サブエージェントがブラウザ操作を並列実行する。
  「このサービスの仕様を調べて」「画面一覧を作って」「Webサービスを分析して」
  「サイトの構成を把握して」「UIの仕様書を作って」「仕様を洗い出して」
  「このサイトのspec書いて」「既存サービスの要件整理して」「サービスの仕様を調査して」
  などと言われたとき、またはURLを提示されて仕様・要件について聞かれたときにトリガーする。
  URLが提示されて「どんなサービス？」「何ができる？」のような曖昧な質問でも、
  仕様調査の意図がありそうならこのスキルを使うこと。
---

# Web Spec Explorer

既存のWebサービスをagent-browserで実際に操作・調査し、仕様をspec/に構造化する。
APIや実装の詳細は対象外。ユーザーから見える振る舞い・画面・フローに集中する。

## 前提条件

`agent-browser` CLIが必要。利用できない場合:

```bash
agent-browser --version  # 確認
agent-browser install     # Chrome for Testingのセットアップ（初回のみ）
```

## アーキテクチャ

```
メインエージェント（オーケストレーション）
  ├── サブエージェント: scout（偵察）
  ├── サブエージェント: explorer-{section}（詳細調査）× N 並列
  └── サブエージェント: flow-{name}（フロー検証）× N 並列
```

メインエージェントはブラウザを直接操作しない。すべてのブラウザ操作はサブエージェントに委譲する。
サブエージェントの結果（テキスト要約）を集約し、spec/に構造化するのがメインの仕事。

## セッション管理

サブエージェント間でブラウザが衝突しないよう、必ず `--session` で分離する:

```bash
agent-browser --session scout open https://example.com
agent-browser --session explorer-settings snapshot
agent-browser --session flow-signup click @e5
```

命名規則:
- `scout` — 偵察フェーズ
- `explorer-{section名}` — セクション別の詳細調査
- `flow-{フロー名}` — ユーザーフロー検証
- `headed-{目的}` — headed モード用（後述）

## Headless / Headed の使い分け

デフォルトは headless（フラグなし）。以下の場合のみ `--headed` を使う:

- CAPTCHA やbot検知で操作がブロックされたとき
- OAuth等の外部認証フローでユーザーの手動操作が必要なとき
- 視覚的な確認が必要なとき（レイアウト崩れの調査等）

headed に切り替えるときは、既存セッションとの衝突を防ぐため必ず専用セッションを使う:

```bash
agent-browser --session headed-auth --headed open https://example.com/login
```

headedセッションはユーザー操作が終わったら速やかに閉じる:

```bash
agent-browser --session headed-auth close
```

## リソース保護

### コンテキストウィンドウの保護

snapshot の出力はページによって巨大になる。`--max-output` で制限する:

```bash
agent-browser --session scout snapshot --max-output 8000
```

大きなページは分割して調査する。全体のsnapshotではなく、特定セクションにフォーカス:

```bash
agent-browser --session explorer-settings find role "navigation"
agent-browser --session explorer-settings snapshot --ref @e3 --max-output 5000
```

サブエージェントは生のsnapshot出力をそのまま返さない。
構造化した要約（画面名、項目一覧、アクション一覧）にまとめてから返す。

### レートリミット対策

対象サービスに負荷をかけないこと:

- ページ遷移の間に **1〜2秒の間隔** を空ける（`sleep 1`）
- 同一ページへの重複アクセスを避ける（既に調査済みのURLはスキップ）
- 並列サブエージェント数は **最大3つ** に制限する
- HTTP 429 やCAPTCHA が出たら、間隔を広げてリトライする
- `--allowed-domains` で対象ドメインに限定し、外部リンクを踏まない

```bash
agent-browser --session scout --allowed-domains "example.com,*.example.com" open https://example.com
```

## 認証の取り扱い

### パターン1: ID/パスワード認証

agent-browserのauth vaultを使う。暗号化されてローカルに保存される:

```bash
agent-browser auth save myservice --url https://example.com/login \
  --username user@example.com --password 'secret'
```

サブエージェントでの利用:

```bash
agent-browser --session scout auth login myservice
```

### パターン2: OAuth / SSO

外部プロバイダへのリダイレクトが発生するため、headed モードでユーザーに手動認証してもらう:

1. headed セッションでログインページを開く
2. ユーザーに認証操作を依頼する
3. 認証完了後、cookieをプロファイルに保存する
4. 以降のセッションでプロファイルを共有する

```bash
# 1. ユーザーに手動認証してもらう
agent-browser --session headed-auth --headed --profile /tmp/myservice-profile open https://example.com/login
# → ユーザーが認証操作を完了するのを待つ

# 2. 以降のサブエージェントはプロファイルを使う
agent-browser --session scout --profile /tmp/myservice-profile open https://example.com/dashboard
```

### パターン3: 認証不要

そのまま進む。

### 認証方式の判定

最初のscoutフェーズでログインページの有無を確認する。
ログインが必要な場合、メインエージェントはユーザーに認証方式を確認してから進める。
認証情報をspec/に書き出さないこと。

## 探索フロー

### Phase 1: 準備

メインエージェントが行う:

1. ユーザーに対象URLとスコープを確認
   - 調査対象のURL
   - 調査範囲（全体 or 特定セクション）
   - 認証の要否
   - 除外すべきページ（管理画面等）
2. agent-browser の利用可能性を確認
3. 認証が必要なら上記パターンに従ってセットアップ
4. spec/ ディレクトリを作成

### Phase 2: 偵察（scout サブエージェント）

1つのサブエージェントで実行。サイト全体の構造を把握する。

サブエージェントへの指示テンプレート:

```
agent-browserを使って以下のWebサービスの全体構造を偵察してほしい。

対象URL: {url}
セッション名: scout
認証: {auth_info}
allowed-domains: {domains}

やること:
1. トップページを開き、snapshotとscreenshotを取得
2. ナビゲーション（ヘッダー、サイドバー、フッター）からリンクを抽出
3. 主要なリンク先を順に開き、各ページの概要を記録
4. サイト全体の構造（セクション分け）を把握
5. ログインの要否を確認

ページ遷移ごとにsleep 1を入れること。
--max-output 8000 を使うこと。

以下の形式で結果を返すこと:
- サービス概要（1-2文）
- 画面一覧（URL, 画面名, 概要）をMarkdownテーブルで
- セクション分け（どの画面がどのセクションに属するか）
- 認証の要否と方式
- 特記事項（見つかった制約や特殊な挙動）

生のsnapshot出力は返さないこと。構造化した要約のみ返す。
```

### Phase 3: 詳細調査（explorer サブエージェント × N 並列）

scoutの結果をもとにサイトをセクション分けし、各セクションを別のサブエージェントに割り当てる。
並列数は最大3つ。セクションが4つ以上あれば複数ラウンドに分ける。

各サブエージェントへの指示テンプレート:

```
agent-browserを使って以下のセクションの詳細仕様を調査してほしい。

対象ページ: {pages}
セッション名: explorer-{section}
認証: {auth_info}
allowed-domains: {domains}

各ページについて以下を調査:
1. snapshotを取得し、画面の構成要素を把握
2. フォームがあれば全入力項目を記録（名前、型、必須/任意、placeholder、選択肢）
3. ボタン・リンクを記録（ラベル、遷移先、実行されるアクション）
4. 状態変化があれば記録（タブ切替、モーダル、アコーディオン等）
5. エラー状態を確認（空送信、不正入力でのバリデーションメッセージ）
6. screenshotを /tmp/spec-screenshots/{section}/ に保存

ページ遷移ごとにsleep 1を入れること。
--max-output 8000 を使うこと。
バリデーション確認時は実際にフォームを操作してエラーメッセージを取得すること。

以下の形式で各ページの結果を返すこと:
- 画面名・URL・目的
- レイアウト構成（ヘッダー、メインコンテンツ、サイドバー等）
- 入力項目一覧（テーブル形式: 項目名, 型, 必須, バリデーション, 備考）
- アクション一覧（テーブル形式: ラベル, 種類, 遷移先/動作）
- 状態・表示切替（条件と結果）
- 共通コンポーネント（他ページでも見かけるUI部品）

生のsnapshot出力は返さないこと。
```

### Phase 4: フロー検証（flow サブエージェント × N 並列）

主要なユーザーフローを実際に操作して検証する。
Phase 2-3の結果から重要なフローを特定する（例: 新規登録、ログイン、商品購入、設定変更）。

各サブエージェントへの指示テンプレート:

```
agent-browserを使って以下のユーザーフローを実際に操作し、手順を記録してほしい。

フロー名: {flow_name}
開始URL: {start_url}
セッション名: flow-{flow_name}
認証: {auth_info}
allowed-domains: {domains}

やること:
1. 開始ページからフローを開始
2. 各ステップでsnapshotとscreenshotを取得
3. 操作手順を記録（何をクリック/入力したか）
4. 分岐点があれば記録（条件とそれぞれの結果）
5. エラーケースも1つ以上試す
6. フロー完了まで追跡
7. screenshotを /tmp/spec-screenshots/flows/{flow_name}/ に保存

ページ遷移ごとにsleep 1を入れること。
フォーム入力にはテストデータを使うこと（実際に送信はしない、または送信が安全な場合のみ送信）。

以下の形式で結果を返すこと:
- フロー名・目的
- 前提条件（ログイン必須等）
- ステップ一覧（番号, 画面, 操作, 結果）
- 分岐点（条件, 分岐先A, 分岐先B）
- エラーケース（操作, エラーメッセージ, 復帰方法）
- 完了条件

生のsnapshot出力は返さないこと。
```

### Phase 5: 構造化（メインエージェント）

すべてのサブエージェントの結果を集約し、spec/に構造化する。
出力フォーマットの詳細は `references/output-format.md` を参照。

構造化のポイント:
- 重複を排除し、共通コンポーネントを抽出する
- 画面間の遷移関係を整理する
- 不明点や未調査箇所を明記する（「TODO: 要確認」）
- screenshotへの参照パスを記載する

### Phase 6: レビュー

構造化した結果をユーザーに提示し、フィードバックを受ける:
- 抜け漏れがないか
- 認識が正しいか
- 追加で調査すべき箇所はあるか

フィードバックに基づいて追加調査（Phase 3-4を部分的に再実行）し、spec/を更新する。

## agent-browser 頻出コマンドリファレンス

```bash
# ナビゲーション
agent-browser --session {s} open {url}
agent-browser --session {s} back
agent-browser --session {s} reload

# 調査
agent-browser --session {s} snapshot --max-output 8000    # アクセシビリティツリー（refつき）
agent-browser --session {s} snapshot --ref @e3            # 特定要素のサブツリー
agent-browser --session {s} screenshot /tmp/page.png      # スクリーンショット
agent-browser --session {s} get text --ref @e5            # 要素のテキスト取得
agent-browser --session {s} get url                       # 現在のURL
agent-browser --session {s} get title                     # ページタイトル

# 操作
agent-browser --session {s} click @e2
agent-browser --session {s} fill @e3 "test@example.com"
agent-browser --session {s} select @e4 --value "option1"
agent-browser --session {s} check @e5
agent-browser --session {s} press Enter
agent-browser --session {s} scroll down 500
agent-browser --session {s} hover @e6

# 要素の発見
agent-browser --session {s} find role "button"
agent-browser --session {s} find text "ログイン"
agent-browser --session {s} find placeholder "メールアドレス"

# 状態確認
agent-browser --session {s} is visible @e3
agent-browser --session {s} is enabled @e4
agent-browser --session {s} wait text "読み込み完了" --timeout 10000

# セッション管理
agent-browser --session {s} close                         # セッション終了
```

ref（@e1, @e2...）はsnapshotで取得できる。操作対象はrefで指定するのが基本。

## 注意事項

- **本番データに触れない**: フォーム送信は原則しない。バリデーション確認のための空送信や不正値入力は可。実データの作成・変更・削除は絶対にしない
- **認証情報をspec/に書かない**: auth.mdには認証方式の仕様のみ記載。パスワードやトークンは書かない
- **外部リンクを踏まない**: `--allowed-domains` で対象ドメインに限定する
- **screenshotの保存先**: `/tmp/spec-screenshots/` 配下に整理して保存。spec/からは相対パスで参照
- **探索の深さ**: 全ページを完全に網羅する必要はない。重要度の高いページとフローに集中し、低優先度のページは画面一覧に名前だけ記載して「TODO: 詳細未調査」とする
