# 最終レポートフォーマット

## 出力先

`{output_dir}/report.md`

## テンプレート

```markdown
# Browser Verify Report

**実行日時**: {日時}
**テストソース**: {ファイルパス}
**サーバー**: http://localhost:{port}
**修正ラウンド**: {数}回

---

## サマリー

| 項目 | 値 |
|---|---|
| テストケース総数 | {数} |
| PASS | {数} |
| FAIL | {数} |
| PASS率 | {数}% |
| 起票Issue数 | {数} |

---

## シードデータ

{seed-data.md の要約。投入データ・アカウント情報等}

---

## テスト結果一覧

| TC | テスト名 | 種別 | 最終結果 | 初回結果 | 修正ラウンド | 備考 |
|----|---------|------|---------|---------|-------------|------|
| TC-001 | {名前} | 正常系 | PASS | PASS | - | |
| TC-002 | {名前} | 異常系 | PASS | FAIL | Round 1 | {修正内容の要約} |
| TC-003 | {名前} | 正常系 | FAIL | FAIL | Round 1-3 | {未解決の理由} |

---

## 起票した Issue

{FAILがある場合のみ記載}

| # | Issue | TC | 分類 | タイトル |
|---|-------|-----|------|---------|
| 1 | #{Issue番号} | TC-002, TC-005 | 実装バグ | {タイトル} |
| 2 | #{Issue番号} | TC-003 | デザイン差異 | {タイトル} |

---

## 失敗詳細

{FAILがある場合のみ記載}

### TC-{番号}: {テスト名}

- **失敗ステップ**: Step {N}
- **期待**: {期待結果}
- **実際**: {実際の結果}
- **分類**: {実装バグ/テスト手順の問題/環境問題/デザイン差異}
- **原因分析**: {分析結果}
- **対応Issue**: #{Issue番号}
- **スクリーンショット**: `screenshots/tc-{番号}/fail-step-{N}.png`

---

## スクリーンショット一覧

{output_dir}/screenshots/ 配下のファイル一覧

| TC | ステップ | ファイル | 備考 |
|----|---------|---------|------|
| TC-001 | Step 1 | `screenshots/tc-001/step-01.png` | |
| TC-001 | Step 2 | `screenshots/tc-001/step-02.png` | |
| TC-002 | Step 1 | `screenshots/tc-002/step-01.png` | |
| TC-002 | Fail | `screenshots/tc-002/fail-step-03.png` | 修正前 |
| TC-002 | Step 3 (Round 1) | `screenshots/tc-002/round1-step-03.png` | 修正後 |

---

## 環境情報

- **OS**: {uname -s}
- **Node.js**: {node --version（該当する場合）}
- **agent-browser**: {agent-browser --version}
- **サーバーコマンド**: {起動コマンド}
- **ポート**: {port}
```
