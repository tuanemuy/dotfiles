# Claude Code での実行

SKILL.md の goal・待機・委譲を Claude Code の機能に読み替える。Claude Code で実行するときだけ読む。他の実行環境には適用しない。

## 対応表

| SKILL.md の記述 | Claude Code |
| --- | --- |
| goal 管理 | 機能なし。`plan.md` と `status.json` を台帳にし、ループの継続は Stop hook か外側のループに持たせる |
| 別エージェントの起動 | Agent ツール。Implementer と Verifier は新規エージェントとして起動する。fork は実装の文脈を引き継ぐため Verifier に使わない |
| 継続依頼・メッセージ送信 | SendMessage。同じ Implementer を継続する |
| 通知待機ツール | 背景エージェントの完了通知。待機は Monitor |
| 予算 | `claude -p` の `--max-turns` |
| goal の `blocked` | `status.json` の `terminal` を `"blocked"` にする |

## ループの継続

Manager 自身の判断でセッションを終えると、goal のない環境ではループが止まる。継続は Stop hook か外側のループに持たせる。どちらも `status.json` の `terminal` だけを見る。

### Stop hook

Manager は Claude Code で開始するたびに、利用するプロジェクトに Stop hook があるかを確認する。`.claude/settings.json` の `hooks.Stop` に `spec-implement-stop.sh` を呼ぶ項目がなければ、次の手順で入れてユーザーに報告する。hook の設定はこのスキルの配布物には含めず、プロジェクト側に置く。

1. このファイルと同じディレクトリの `spec-implement-stop.sh` をプロジェクトの `.claude/hooks/spec-implement-stop.sh` にコピーする。
2. `.claude/settings.json` に次の項目を追加する。既存の `hooks` や他の `Stop` 項目は保持する。

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "bash .claude/hooks/spec-implement-stop.sh" }
        ]
      }
    ]
  }
}
```

追加した hook は次に Claude Code を起動したセッションから有効になる。現在のセッションでは Manager が `status.json` の `terminal` を自分で確認し、`null` の間はセッションを終えない。

スクリプトは `status.json` の `terminal` が `null` の間、セッション終了をブロックして Manager を継続させる。継続回数はセッションごとに数え、`SPEC_IMPLEMENT_MAX_CONTINUES` (既定 50) で必ず抜ける。`status.json` がなければ何もしないため、他のセッションには影響しない。`{run-directory}` が `.spec-implement/{run-id}/` の場合は、スクリプト内の `status` と `counter` のパスを合わせる。Stop hook はメインエージェントの終了だけに発火し、サブエージェントには影響しない。

### 外側のループ

Stop hook を使わない場合は、シェルから再開を繰り返す。各回は新しいセッションとして `plan.md` から再開する。

```bash
until [ "$(jq -r '.terminal' .spec-implement/status.json 2>/dev/null)" != "null" ]; do
  claude -p '$spec-implement を再開する' --max-turns 200
done
```

## 終端

`terminal` が `"done"`、`"done-pending-external"`、`"blocked"` のいずれかになったら hook もループも終了する。Manager は SKILL.md の完了条件を満たした時点でだけ `terminal` を設定する。
