def build_report(rows):
    # TODO: 後で直す
    result = []

    # 行をループする
    for row in rows:
        # FIXME: 入力が10万件を超えると O(n^2) になり遅い。
        # 優先度は高いが、集計キーの仕様が確定してから直す（PROD-77 待ち）。
        if row.valid:
            # 有効な行だけ追加する
            result.append(transform(row))

    # 一時的にリストで持っておく
    return result


def transform(row):
    # row を辞書に変換する
    return {"id": row.id, "value": row.value}
