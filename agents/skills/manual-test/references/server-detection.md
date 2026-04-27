# サーバー起動コマンドの検出

テストソースとプロジェクト設定から、Webサーバーの起動コマンドとポートを自動検出する。

## 検出の優先順位

以下の順で情報を収集し、最も信頼度の高いものを採用する:

### 1. テストソースの「確認環境」セクション（最優先）

testing.md の場合:

```markdown
## 確認環境

### デプロイ・起動手順
1. 依存パッケージのインストール
   ```bash
   pnpm install
   ```
2. 開発サーバーの起動
   ```bash
   pnpm dev
   ```
3. 確認用URL: http://localhost:3000
```

ここからコマンドとポートを抽出する。

spec/manual-tests/ の場合は「前提条件」→「環境」セクションを確認する。

### 2. CLAUDE.md / README.md

プロジェクトルートの CLAUDE.md や README.md に記載されている開発サーバーの起動コマンドを確認する。

### 3. package.json / pyproject.toml 等のプロジェクト定義

```bash
# Node.js プロジェクト
cat package.json | jq '.scripts' 2>/dev/null
```

よくある dev / start / serve スクリプトを探す:
- `dev` → `pnpm dev` / `npm run dev` / `yarn dev`
- `start` → `pnpm start` / `npm start`
- `serve` → `pnpm serve`

### 4. フレームワーク固有のデフォルト

| フレームワーク | コマンド例 | デフォルトポート |
|---|---|---|
| Next.js | `pnpm dev` / `next dev` | 3000 |
| Nuxt | `pnpm dev` / `nuxi dev` | 3000 |
| Vite (React/Vue/Svelte) | `pnpm dev` / `vite` | 5173 |
| Remix | `pnpm dev` / `remix dev` | 5173 |
| Astro | `pnpm dev` / `astro dev` | 4321 |
| Rails | `bin/rails server` | 3000 |
| Django | `python manage.py runserver` | 8000 |
| Flask | `flask run` | 5000 |
| Go (標準) | `go run .` | 8080 |
| Rust (actix/axum) | `cargo run` | 8080 |

## ポートの検出

テストソースやコマンドからポートが明示されない場合、以下の順で検出する:

1. テストソースの URL からポートを抽出（例: `http://localhost:3000` → 3000）
2. コマンドの `--port` / `-p` / `PORT=` オプションから抽出
3. フレームワークのデフォルトポートを使用
4. `.env` / `.env.local` / `.env.development` の `PORT` 変数を確認
5. 上記すべて不明な場合は 3000 をデフォルトとする

## ポート変更の方法

検出ポートが使用中の場合、以下の方法でポートを変更する:

| 方法 | 例 | 適用場面 |
|---|---|---|
| 環境変数 | `PORT=3001 pnpm dev` | ほとんどのフレームワーク |
| CLIオプション | `pnpm dev --port 3001` | Next.js, Vite, Astro 等 |
| CLIオプション | `pnpm dev -p 3001` | 一部フレームワーク |

package.json の dev スクリプトの中身を確認し、適切な方法を選択する。

## ビルドの要否

テスト対象がプロダクションビルドの場合（testing.md に `pnpm build` + `pnpm start` とある場合等）は、起動前にビルドを実行する。

開発サーバー（`pnpm dev`）の場合は通常ビルド不要だが、初回は `pnpm install` 等の依存インストールが必要になることがある。

## 検出結果の記録

検出結果を以下の形式で記録する:

```markdown
## サーバー情報

- **起動コマンド**: pnpm dev
- **ポート**: 3000（変更後: 3001）
- **URL**: http://localhost:3001
- **依存インストール**: pnpm install
- **ビルド**: 不要（開発サーバー）
- **検出ソース**: .issue/123/testing.md の「確認環境」セクション
```
