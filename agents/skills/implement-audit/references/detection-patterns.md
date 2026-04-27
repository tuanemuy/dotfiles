# 検出パターン定義

未完成コードを検出するためのパターンを定義する。言語非依存のパターンと、言語固有のパターンがある。

## 1. 明示的マーカー

コメント内のマーカーキーワード。大文字・小文字を区別しない。

### パターン

```
TODO
FIXME
HACK
XXX
TEMP
PLACEHOLDER
WORKAROUND
REVISIT
REFACTOR
INCOMPLETE
```

### Grep コマンド例

```bash
# 一括検索（大文字小文字区別なし）
grep -rni "TODO\|FIXME\|HACK\|XXX\|TEMP\b\|PLACEHOLDER\|WORKAROUND\|REVISIT\|REFACTOR\|INCOMPLETE" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.go" --include="*.rs" --include="*.py"
```

ただし Grep ツールを使う場合は正規表現で:
```
(?i)(TODO|FIXME|HACK|XXX|TEMP\b|PLACEHOLDER|WORKAROUND|REVISIT|REFACTOR|INCOMPLETE)
```

### 判定

- `TODO` / `FIXME` → **Critical**（明示的に未完了を宣言している）
- `HACK` / `WORKAROUND` / `TEMP` → **Warning**（暫定対応の可能性）
- `REVISIT` / `REFACTOR` → **Info**（改善余地の示唆）

---

## 2. 未実装シグナル

関数やメソッドが存在するが、実質的に何も実装されていないパターン。

### 言語共通パターン

```
not implemented
not yet implemented
to be implemented
implementation pending
needs implementation
```

### TypeScript / JavaScript

```regex
throw new Error\(["']not implemented["']\)
throw new Error\(["']Not implemented["']\)
throw new Error\(["']TODO["']\)
return undefined\s*;?\s*//
return null\s*;?\s*//
return \{\}\s*;?\s*//
return \[\]\s*;?\s*//
```

空の関数ボディ:
```regex
\)\s*\{[\s\n]*\}
=>\s*\{[\s\n]*\}
```

### Go

```regex
panic\("not implemented"\)
panic\("TODO"\)
return nil\s*//
return errors\.New\("not implemented"\)
```

空の関数ボディ:
```regex
func\s+\w+\([^)]*\)[^{]*\{[\s\n]*\}
```

### Python

```regex
raise NotImplementedError
pass\s*$
```

空の関数ボディ:
```regex
def\s+\w+\([^)]*\):\s*\n\s+pass
```

### Rust

```regex
unimplemented!\(\)
todo!\(\)
panic!\("not implemented"\)
```

### 判定

- `throw new Error("not implemented")` 系 → **Critical**
- 空の関数ボディ → **Warning**（意図的な場合もある）
- `pass`（Python）→ コンテキストに依存（抽象メソッドなら正当）

---

## 3. 省略シグナル

コードの一部が省略されたことを示すパターン。AI によるコード生成で特に多い。

### パターン

```regex
//\s*\.\.\.
/\*\s*\.\.\.\s*\*/
#\s*\.\.\.
<!--\s*\.\.\.\s*-->
\.\.\.\s*$
```

日本語の省略コメント:
```regex
(?i)(省略|abbreviated|omitted|以下同様|残りは|その他は|同様に|ここに|追加する|追加予定|実装する|実装予定)
```

英語の省略コメント:
```regex
(?i)(rest of|remaining|similar to above|add .+ here|implement .+ here|more .+ here|etc\.\s*$)
```

### 判定

- `// ...` や `/* ... */` → **Critical**（明らかなコード省略）
- 「ここに〜を追加」系のコメント → **Critical**（未完成の指示）
- 「以下同様」「残りは」→ **Warning**（省略の可能性）

---

## 4. 仮実装シグナル

本来は動的な値や外部設定であるべきものがハードコードされているパターン。

### パターン

```regex
(?i)(dummy|stub|fake|hardcoded|hard-coded|hardcode|hard.?code|temporary|tmp_|temp_|sample_|example_)
```

テスト以外のファイルでの mock:
```regex
(?i)(mock(?!\.test|\.spec|_test|_spec|test_|spec_))
```

仮のURL・認証情報:
```regex
(https?://example\.com|https?://localhost|password123|secret123|test@test\.com|admin@admin\.com)
```

### 判定

- テスト以外での `dummy`, `stub`, `fake` → **Warning**
- ハードコードされた認証情報 → **Critical**（セキュリティリスク）
- `example.com` 等のプレースホルダーURL → **Warning**

---

## 5. 不完全な制御フロー

エラーハンドリングや分岐処理が省略されているパターン。

### TypeScript / JavaScript

```regex
catch\s*\([^)]*\)\s*\{[\s\n]*\}
catch\s*\{[\s\n]*\}
```

空の default ケース:
```regex
default:\s*\n\s*(break|return)\s*;?\s*\n
```

### Go

```regex
if err != nil \{\s*\n\s*\}
_ = \w+  // エラーを明示的に無視
```

### Python

```regex
except.*:\s*\n\s+pass
except:\s*\n\s+pass
```

### 判定

- 空の catch/except → **Warning**（意図的な場合もあるがレビュー必要）
- エラー握り潰し → **Warning**
- 空の default → **Info**

---

## 除外パターン

以下のパスやファイルはスキャン対象から除外する:

### ディレクトリ

```
node_modules/
vendor/
.next/
dist/
build/
out/
target/
__pycache__/
.git/
.audit/
```

### ファイル

```
*.lock
*.generated.*
*.g.dart
*.pb.go
*.min.js
*.min.css
*.map
```

### コンテキスト除外

- テストファイル（`*.test.*`, `*.spec.*`, `*_test.*`, `test_*.*`）内の `mock`, `stub`, `dummy`, `fake` は除外
- `spec/` ディレクトリ内のドキュメントは Phase 2 の対象外（Phase 4 で別途照合）
- CLAUDE.md, README.md 等のプロジェクトドキュメントは対象外
