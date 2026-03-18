---
name: feed
description: はてなブックマークIT人気エントリー、Hacker News、Reddit、GitHub Trendingの人気記事・リポジトリを収集し、`feed/yyyyMMdd.md` に保存します。
---

はてなブックマークIT人気エントリー、Hacker News、Reddit、GitHub Trendingの人気記事・リポジトリを収集し、ユーザーの興味領域にマッチするトピックを分析して、`feed/yyyyMMdd.md` に保存します。

## 実行手順

### 0. ユーザーの興味領域の理解

以下の興味領域を理解する：

- AI（開発とセキュリティへの応用）
- Webセキュリティ/ハッキング（OWASP、脆弱性、サプライチェーン攻撃）
- OSS開発/コミュニティ
- 個人開発/SaaS運営（Technical SEO、グロースハック、収益化）
- JavaScript/TypeScript技術スタック
- プログラミング言語全般（特にRust、関数型言語、モダンな言語）
- Neovim/Vim（プラグイン、設定、エコシステム）
- ターミナル/CLI（シェル、ターミナルエミュレータ、CLIツール）
- デザイン/UI・UX（インタラクションデザイン、デザインシステム、タイポグラフィ、アクセシビリティ、デザインツール）
- 生産性

### 1. トレンド情報の収集

以下のサイトから最新のトレンド情報を取得：

#### はてブIT

- <https://b.hatena.ne.jp/hotentry/it>
- <https://b.hatena.ne.jp/hotentry/it/%E3%83%97%E3%83%AD%E3%82%B0%E3%83%A9%E3%83%9F%E3%83%B3%E3%82%B0>
- <https://b.hatena.ne.jp/hotentry/it/AI%E3%83%BB%E6%A9%9F%E6%A2%B0%E5%AD%A6%E7%BF%92>
- <https://b.hatena.ne.jp/hotentry/it/%E3%81%AF%E3%81%A6%E3%81%AA%E3%83%96%E3%83%AD%E3%82%B0%EF%BC%88%E3%83%86%E3%82%AF%E3%83%8E%E3%83%AD%E3%82%B8%E3%83%BC%EF%BC%89>
- <https://b.hatena.ne.jp/hotentry/it/%E3%82%BB%E3%82%AD%E3%83%A5%E3%83%AA%E3%83%86%E3%82%A3%E6%8A%80%E8%A1%93>
- <https://b.hatena.ne.jp/hotentry/it/%E3%82%A8%E3%83%B3%E3%82%B8%E3%83%8B%E3%82%A2>
- <https://b.hatena.ne.jp/hotentry/it/%E3%83%87%E3%82%B6%E3%82%A4%E3%83%B3>

- 各エントリーの**タイトル、元記事URL、ブックマーク数**を必ず取得すること
- はてブのエントリーページURLではなく、リンク先の元記事URLを抽出

#### Hacker News

- <https://news.ycombinator.com/>

- 各記事の**タイトル、HNコメントページURL（`https://news.ycombinator.com/item?id=XXXXX`形式）、ポイント数**を取得
- **元記事URLではなくHNのコメントページURLを使用すること**（コメントも確認できるようにするため）
- **タイトルは日本語に翻訳して出力**

#### Reddit

- **重要**: WebFetchツールはreddit.comをブロックするため、**Bashツールでcurlコマンドを使用**すること
- 各サブレッドから `/hot.json?t=day&limit=10` で上位10件を取得
- **old.reddit.com**を使用（www.reddit.comではない）
- User-Agentヘッダーを設定: `"User-Agent: neta-trend-collector/1.0 (trend analysis tool)"`
- 各記事の**タイトル、Redditコメントページの完全URL、投票数（ups）、コメント数**を取得
- **タイトルは日本語に翻訳して出力**

##### 取得例（Bashツールで実行）:

```bash
curl -s -H "User-Agent: neta-trend-collector/1.0 (trend analysis tool)" \
  "https://old.reddit.com/r/programming/hot.json?t=day&limit=10" | \
  jq -r '.data.children[] | "\(.data.title)|\(.data.ups)|\(.data.num_comments)|https://www.reddit.com\(.data.permalink)"'
```

##### データ構造:

- `data.children[].data.title`: タイトル
- `data.children[].data.ups`: 投票数
- `data.children[].data.num_comments`: コメント数
- `data.children[].data.permalink`: パス（`https://www.reddit.com` + permalink で完全URL）

##### 対象サブレッド:

- セキュリティ系
    - r/netsec
    - r/cybersecurity
- AI系
    - r/OpenAI
    - r/LocalLLaMA
    - r/ClaudeCode
- コア技術系
    - r/programming
    - r/technology
- Neovim/ターミナル系
    - r/neovim
    - r/commandline
- OSS/個人開発系
    - r/opensource
    - r/indiehackers
    - r/webdev
    - r/javascript
- デザイン/UI・UX系
    - r/UI_Design
    - r/userexperience
    - r/web_design
- 実践系
    - r/productivity

##### フォールバック: RSSフィード

JSON APIがブロックされた場合（`"Your request has been blocked"` レスポンス）、**RSSフィードにフォールバック**する。

```bash
curl -s -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" \
  "https://www.reddit.com/r/programming/hot/.rss" | \
  python3 -c "
import sys, xml.etree.ElementTree as ET
data = sys.stdin.read()
root = ET.fromstring(data)
ns = {'atom': 'http://www.w3.org/2005/Atom'}
for entry in root.findall('atom:entry', ns)[:10]:
    title = entry.find('atom:title', ns).text if entry.find('atom:title', ns) is not None else ''
    link = entry.find('atom:link', ns).get('href', '') if entry.find('atom:link', ns) is not None else ''
    print(f'{title}|{link}')
"
```

- RSSフィードでは**投票数・コメント数は取得不可**（注記として出力に記載する）
- `www.reddit.com`のRSSを使用（`old.reddit.com`ではない）
- User-Agentはブラウザ風に設定

#### GitHub Trending

WebFetchツールで以下の4ページを取得：

- <https://github.com/trending>（全言語）
- <https://github.com/trending/typescript>
- <https://github.com/trending/rust>
- <https://github.com/trending/javascript>

- 各リポジトリの**リポジトリ名（owner/repo）、説明、言語、今日のスター数、総スター数**を取得
- **4ページは並列で取得**すること（WebFetchを同時に4回呼ぶ）
- リポジトリ名にはGitHubへのリンクを付与（`https://github.com/owner/repo` 形式）

### 2. 分析

収集した情報を以下の観点で分析：

### 興味領域マッチング（最優先）

- 各記事を興味領域と照合し、関連度を評価
- 高関連度の記事を「注目トピック」の最上位に配置
- 特に注目すべきトピック：
    - AI（開発とセキュリティへの応用）
    - Webセキュリティ/ハッキング（OWASP、脆弱性、サプライチェーン攻撃）
    - OSS開発/コミュニティ
    - 個人開発/SaaS運営（Technical SEO、グロースハック、収益化）
    - JavaScript/TypeScript関連（新技術、ツール、フレームワーク）
    - プログラミング言語全般（特にRust、関数型言語、モダンな言語）
    - Neovim/Vim（プラグイン、設定、エコシステム）
    - ターミナル/CLI（シェル、ターミナルエミュレータ、CLIツール）
    - デザイン/UI・UX（インタラクションデザイン、デザインシステム、タイポグラフィ、アクセシビリティ、デザインツール）
    - 生産性

#### はてブIT

- 日本のエンジニアに刺さりやすい話題
- 議論を呼びそうなトピック
- 技術トレンド（AI、開発手法、ツール等）

#### Hacker News

- グローバルで話題の技術トレンド
- スタートアップ・プロダクト関連
- セキュリティ関連（脆弱性、攻撃手法、インシデント）
- 議論を呼んでいるトピック（ポイント数が高い）

#### Reddit

- セキュリティ系：最新の脅威、実践的な攻撃・防御手法
- AI系：OpenAI、ローカルLLM、Claude Code関連
- OSS/個人開発系：OSSプロジェクト、個人開発、Web開発
- デザイン/UI・UX系：UIデザイントレンド、UXリサーチ手法、デザインシステム、アクセシビリティ
- 投票数（ups）とコメント数でコミュニティの反応を評価
- 議論が活発なトピック（コメント数が多い）を優先

#### GitHub Trending

- 興味領域に関連するリポジトリを優先的にピックアップ
- 今日のスター数が多いリポジトリに注目
- 言語別（TypeScript、Rust、JavaScript）のトレンドも個別に分析
- 新興プロジェクト（総スター数が少ないのに今日のスターが多い）に特に注目
- OSS開発・ツール・フレームワークの新しい動きを捉える

### 3. 出力

結果を `feed/yyyyMMdd$md` に保存。

以下のフォーマットで出力：

```markdown
# Daily Digest: YYYY-MM-DD

## はてブIT

### 注目トピック

| タイトル | ブクマ数 | 興味度 | カテゴリ | コメント |
|---------|---------|--------|---------|------|
| [タイトル](元記事URL) | XXX users | ★★★/★★/★ | AI/開発等 |  |

**興味度の定義**:
- ★★★: 興味領域に直接関連
- ★★: 間接的に関連
- ★: 一般的なIT/技術ニュース

### 全エントリー

1. [タイトル](元記事URL) (XXX users) - 概要
2. ...

## Hacker News

### 注目トピック

| タイトル | ポイント | 興味度 | カテゴリ | コメント |
|---------|---------|--------|---------|------|
| [タイトル](HNコメントページURL) | XXXpt | ★★★/★★/★ | AI/Security/Dev等 | |

### 全エントリー

1. [タイトル](HNコメントページURL) (XXXpt) - 概要
2. ...

## Reddit

### 注目トピック

| タイトル | 投票数 | コメント数 | 興味度 | カテゴリ | サブレッド | コメント |
|---------|--------|-----------|--------|---------|-----------|------|
| [タイトル](Redditコメントページ完全URL) | XXX ups | XXX | ★★★/★★/★ | Security/AI/OSS等 | r/subreddit | 発信に活用できるポイント |

### 全エントリー

1. [タイトル](RedditコメントページURL) (XXX ups, XXX comments) - r/netsec - 概要
2. ...

## GitHub Trending

### 注目リポジトリ

| リポジトリ | 言語 | 今日のスター | 総スター | 興味度 | カテゴリ | コメント |
|-----------|------|------------|---------|--------|---------|------|
| [owner/repo](https://github.com/owner/repo) | TypeScript | +XXX | XX,XXX | ★★★/★★/★ | AI/OSS/Rust等 | 注目ポイント |

### 全リポジトリ

1. [owner/repo](https://github.com/owner/repo) (+XXX) - 説明
2. ...
```

## 注意事項

- WebFetchツールを使用して情報を取得
- **すべての記事・リポジトリにURLリンクを必ず含める（リンクなしは不可）**
- **はてブは元記事のURLを必ず取得**（はてブページURLではなく）
- **Hacker NewsはHNコメントページURL（`item?id=`形式）を使用**（元記事URLではなく）
- **Hacker Newsのタイトルは日本語に翻訳**
- **RedditはRedditコメントページの完全URL（`https://www.reddit.com/r/subreddit/comments/...`形式）を使用**
- **Redditのタイトルは日本語に翻訳**
- Reddit JSON APIがブロックされた場合はRSSフィードにフォールバック（投票数・コメント数は取得不可になる旨を注記）
- **GitHub Trendingは4ページ（Overall、TypeScript、Rust、JavaScript）を並列取得**
- **GitHub Trendingのリポジトリ名は`https://github.com/owner/repo`形式のリンクを付与**
- 投票数（ups）/コメント数/スター数が高い記事・リポジトリを優先
- ポイント数/ブックマーク数が高い記事は特に注目
- 出力ファイルのyyyyMMddは実行日の日付を使用
- 出力のセクション順序: **GitHub Trending → はてブIT → Hacker News → Reddit**
