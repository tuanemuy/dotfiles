def build_report(rows):
    result = []

    for row in rows:
        # 入力が10万件を超えると O(n^2) になり遅い。
        # 集計キーの仕様が確定してから直す（PROD-77 待ち）。
        if row.valid:
            result.append(transform(row))

    return result


def transform(row):
    return {"id": row.id, "value": row.value}
