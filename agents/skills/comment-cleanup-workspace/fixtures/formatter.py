from decimal import Decimal


def format_money(amount: Decimal, currency: str) -> str:
    """金額を表示用の文字列にフォーマットする。

    Created: 2023-11-02 by yamada
    Changelog:
      - 2023-11-02: 初版（円のみ対応）
      - 2024-01-15: USD 対応を追加
      - 2024-05-03: 端数処理を四捨五入から切り捨てに変更（経理チーム要望 TICKET-882）

    Args:
        amount: 金額（主単位。最小単位ではない）
        currency: ISO 4217 の通貨コード

    Returns:
        表示用にフォーマットされた文字列
    """
    # currency が JPY かどうかをチェックする
    if currency == "JPY":
        # 日本円は小数点以下を表示しない
        # 端数は切り捨てる。経理の要望で四捨五入だと合計が合わなくなるケースがあったため。
        whole = int(amount)
        return f"¥{whole:,}"

    # それ以外の通貨は小数点2桁で表示する
    cents = quantize(amount)
    # 通貨コードを前につけて返す
    return f"{currency} {cents}"


def quantize(amount: Decimal) -> Decimal:
    # amount を小数点2桁に丸める
    return amount.quantize(Decimal("0.01"))
