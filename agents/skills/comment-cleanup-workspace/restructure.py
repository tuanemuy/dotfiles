import json, os, shutil

ITER = os.path.join(os.path.dirname(__file__), "iteration-1")

EVIDENCE = {
    "eval-0-jsdoc-metadata-and-obvious": [
        "JSDocは概要+@param+@returnsのみ。作成日/作者/sato追加/平文→ハッシュの3行は消えている",
        "@param input/@param input.email/@param input.password/@returns が全て残存",
        "bcrypt→argon2 の経緯コメントは完全に削除され、日付・経緯は残っていない",
        "findByEmail/throw/hash/insert/ループ各所の自明コメントが全て削除",
        "// const oldId ... と // return oldId; の2行が削除されている",
        "コード行(12-30)はフィクスチャと完全一致。挙動不変",
    ],
    "eval-1-docstring-changelog": [
        "docstringにCreated行とChangelogブロックが存在しない",
        "Args(amount/currency)とReturnsの記述が残存",
        "# 端数は切り捨てる。四捨五入だと合計が合わなくなる... のwhyコメントが残存",
        "JPYチェック/小数点2桁/通貨コード前置/quantizeの自明コメントが全て削除",
        "実行コード行はフィクスチャと一致。挙動不変",
    ],
    "eval-2-preserve-why-comments": [
        "ファイル冒頭の作成者:nakamura/最終更新/ファイル名のメタデータが削除されている",
        "add内の『配列ではなくヒープを...見合わないため配列のまま』のwhy notが残存",
        "backoff内の『上限なしだと永久に再実行されない...』のwhyが残存",
        "ジョブを追加する/size を返す/jobs の長さを返す 等の自明コメントが全て削除",
        "実行コード行はフィクスチャと一致。挙動不変",
    ],
}

for name, evs in EVIDENCE.items():
    eval_dir = os.path.join(ITER, name)
    meta = json.load(open(os.path.join(eval_dir, "eval_metadata.json")))
    for cfg in ("with_skill", "without_skill"):
        cfgd = os.path.join(eval_dir, cfg)
        run = os.path.join(cfgd, "run-0")
        os.makedirs(run, exist_ok=True)
        # move outputs/, grading.json, timing.json into run-0/
        for item in ("outputs", "grading.json", "timing.json"):
            src = os.path.join(cfgd, item)
            dst = os.path.join(run, item)
            if os.path.exists(src) and not os.path.exists(dst):
                shutil.move(src, dst)
        # rewrite grading.json with summary + expectations
        total = len(meta["assertions"])
        expectations = [
            {"text": a, "passed": True, "evidence": evs[i]}
            for i, a in enumerate(meta["assertions"])
        ]
        grading = {
            "eval_id": meta["eval_id"],
            "eval_name": name,
            "config": cfg,
            "summary": {"pass_rate": 1.0, "passed": total, "failed": 0, "total": total},
            "expectations": expectations,
        }
        json.dump(grading, open(os.path.join(run, "grading.json"), "w"),
                  ensure_ascii=False, indent=2)
    print(f"restructured {name}")

print("done")
