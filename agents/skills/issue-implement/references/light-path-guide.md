# ライトパスガイド

Phase 0 でライトと判定された Issue の短縮フロー。計画・デザイン・ブラウザ動作検証・スコープ外起票を省く。

```text
ブランチ作成 → 実装 → Draft PR → 軽レビュー（最大2R）→ Ready for review
→ ダッシュボード更新 → コメント整理
```

## 原則

- 計画ファイル（plan.md 等）も `.thread/{Issue番号}/` も作らない。**契約は Issue 本文**。中間成果物は `{scratchpad}/light/{Issue番号}/` に置く（定義は `../../_shared/references/scratchpad.md`）。
- 指摘台帳・ADR は作らない。それらが要るほど指摘・判断が出るのはライト誤判定のシグナル。
- メインはオーケストレーションに徹する。実装・レビュー・修正はサブエージェント（**判断区分**）に委譲し、中断時の再委譲も含めて `../../_shared/references/subagent-policy.md` に従う。

## エスカレーション

- **実装着手前**に前提が崩れた（影響範囲が広い、設計判断が必要）→ 判定の訂正を宣言してフルフロー Phase 1 へ。ブランチは使い回してよい。
- **実装後**に崩れた（実装担当が「設計判断が必要」と報告、レビューが2ラウンドで未収束）→ Draft のまま停止し、ユーザーに判断を委ねる。

## 手順

1. **ブランチ作成** — `implementation-guide.md` Step 1 と同じ（`.gitignore` 確認は不要）。
2. **実装** — サブエージェント1体に委譲。`implementation-guide.md` Step 2 のプロンプトをベースに、steps.md / plan.md / デザインモック / adr.md への言及を Issue 本文（転記）に置き換え、「Issue の意図を満たす最小の変更に絞る」「非自明な設計判断が必要なら実装せず報告する」を指示する。変異スポットチェックは維持。完了後、メインが typecheck・lint・テストで整合性を確認する。
3. **Draft PR 作成** — `implementation-guide.md` Step 4 に準じる。Test plan には実行したコマンドと結果を書き、`> Light path: 計画・ブラウザ動作検証は省略` を明記する。
4. **軽レビュー（最大2ラウンド）** — 差分を `{scratchpad}/light/{Issue番号}/round-{N}.diff` に書き出し、レビュアー1体（**判断区分**・`general` 相当）を起動。判定基準は Issue 本文と CLAUDE.md、観点は `review-guide.md` Step 3 の5観点（範囲は差分全量×1体）。レビューは `{scratchpad}/light/{Issue番号}/review-{N}.md` に直接書かせ、返答は件数と一行リストのみ。指摘はメインが fix / skip を判断（skip の理由は完了報告に一行）、fix は委譲で修正 → 品質ゲート → コミット・push。fix があったときだけラウンド2で確認し、fix ゼロで APPROVED。ラウンド2でも fix が出たらエスカレーション（実装後）。
5. **Ready for review** — 全修正の push を確認して `gh pr ready`。
6. **ダッシュボード更新** — `../SKILL.md` Phase 6 と同じ。
7. **コメント整理** — `../SKILL.md` Phase 8 と同じ。差分がなければスキップ。

## 完了報告（短縮版）

```text
Issue #{Issue番号} の実装が完了しました！（ライトパス）
- 判定: ライト（{理由を一言}）
- PR: #{PR番号}（Ready for review）／ブランチ: issue/{Issue番号}/{短い説明}
- レビュー: {N}ラウンド・指摘{数}件（fix {数} / skip {数}: {理由}）
- ダッシュボード: {更新/スキップ}／コメント整理: {実施/差分なし}
- 省略: 計画・デザイン・ブラウザ動作検証・スコープ外起票
- スコープ外の気づき: {一行で列挙、またはなし}（起票せず報告のみ）
```
