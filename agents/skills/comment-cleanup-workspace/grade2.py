import json, os

ITER = os.path.join(os.path.dirname(__file__), "iteration-2")

TIMING = {
    ("eval-0-pseudo-vs-real-why", "with_skill"): (22813, 16729, 16.7),
    ("eval-0-pseudo-vs-real-why", "without_skill"): (22089, 19364, 19.4),
    ("eval-1-todo-with-reason", "with_skill"): (22809, 22005, 22.0),
    ("eval-1-todo-with-reason", "without_skill"): (22125, 22647, 22.6),
    ("eval-2-buried-why-in-verbose", "with_skill"): (23250, 27657, 27.7),
    ("eval-2-buried-why-in-verbose", "without_skill"): (22370, 24545, 24.5),
    ("eval-3-over-delete-guard", "with_skill"): (22260, 18534, 18.5),
    ("eval-3-over-delete-guard", "without_skill"): (21517, 16361, 16.4),
}

# (passed, evidence) per assertion, per (eval, config). All passed=True here;
# evidence captures the honest qualitative divergences.
GRADES = {
    ("eval-0-pseudo-vs-real-why", "with_skill"): [
        (True, "『レスポンスをキャッシュして高速化する』は削除済み"),
        (True, "『キャッシュにあればそれを返す』『stock を返す』は削除済み"),
        (True, "TTL 5秒の理由（在庫変動・購入時衝突）のwhyが残存"),
        (True, "コード行はフィクスチャと完全一致"),
    ],
    ("eval-0-pseudo-vs-real-why", "without_skill"): [
        (True, "『高速化する』削除（スキルあり版と完全一致の出力）"),
        (True, "自明コメント2件削除済み"),
        (True, "本物のwhyが残存"),
        (True, "コード行不変"),
    ],
    ("eval-1-todo-with-reason", "with_skill"): [
        (True, "『# TODO: 後で直す』削除済み"),
        (True, "O(n^2)・PROD-77・仕様確定待ちの内容は残存。ただし『FIXME:』マーカーと『優先度は高いが』も削除しており、未完了シグナルが弱まっている（要検討）"),
        (True, "ループ/有効行/一時リスト/辞書変換の自明コメント4件削除済み"),
        (True, "コード行不変"),
    ],
    ("eval-1-todo-with-reason", "without_skill"): [
        (True, "『# TODO: 後で直す』削除済み"),
        (True, "『FIXME:』マーカー込みで理由・文脈を完全保持（O(n^2)・優先度・PROD-77）"),
        (True, "自明コメント4件削除済み"),
        (True, "コード行不変"),
    ],
    ("eval-2-buried-why-in-verbose", "with_skill"): [
        (True, "JSDocの逐次説明を7行→2行に圧縮"),
        (True, "安定ソートの理由（同名時に登録順=UI仕様）がJSDocに残存"),
        (True, "filter/sort直前の自明コメント2件削除済み"),
        (True, "タイブレーク行のインラインwhy『名前が同じなら登録順を保つ』を残している"),
        (True, "コード行不変"),
    ],
    ("eval-2-buried-why-in-verbose", "without_skill"): [
        (True, "JSDocを2行に圧縮"),
        (True, "安定ソートの理由をJSDocに残存"),
        (True, "自明コメント2件削除済み"),
        (True, "意図はJSDocに集約。ただし末尾のインラインwhyは削除（情報はdocに保持されるが配置が異なる）"),
        (True, "コード行不変"),
    ],
    ("eval-3-over-delete-guard", "with_skill"): [
        (True, "TSDocの前提条件・未規定の契約が残存（変更ゼロ）"),
        (True, "オーバーフロー回避のwhyが残存"),
        (True, "正当なコメントを一切削除していない（編集ゼロ）"),
        (True, "コード行不変"),
    ],
    ("eval-3-over-delete-guard", "without_skill"): [
        (True, "TSDocの契約が残存（変更ゼロ）"),
        (True, "オーバーフロー回避のwhyが残存"),
        (True, "編集ゼロ。過剰削除なし"),
        (True, "コード行不変"),
    ],
}

for (name, cfg), grades in GRADES.items():
    run = os.path.join(ITER, name, cfg, "run-0")
    meta = json.load(open(os.path.join(ITER, name, "eval_metadata.json")))
    total = len(grades)
    passed = sum(1 for g in grades if g[0])
    expectations = [
        {"text": meta["assertions"][i], "passed": g[0], "evidence": g[1]}
        for i, g in enumerate(grades)
    ]
    grading = {
        "eval_id": meta["eval_id"], "eval_name": name, "config": cfg,
        "summary": {"pass_rate": passed / total, "passed": passed,
                    "failed": total - passed, "total": total},
        "expectations": expectations,
    }
    json.dump(grading, open(os.path.join(run, "grading.json"), "w"),
              ensure_ascii=False, indent=2)
    tok, ms, sec = TIMING[(name, cfg)]
    json.dump({"total_tokens": tok, "duration_ms": ms, "total_duration_seconds": sec},
              open(os.path.join(run, "timing.json"), "w"), indent=2)
    print(f"{name}/{cfg}: {passed}/{total}")
print("done")
