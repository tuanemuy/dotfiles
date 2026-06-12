from decimal import Decimal


def format_money(amount: Decimal, currency: str) -> str:
    """金額を表示用の文字列にフォーマットする。

    Args:
        amount: 金額（主単位。最小単位ではない）
        currency: ISO 4217 の通貨コード

    Returns:
        表示用にフォーマットされた文字列
    """
    if currency == "JPY":
        # 端数は切り捨てる。四捨五入だと合計が合わなくなるケースがあったため。
        whole = int(amount)
        return f"¥{whole:,}"

    cents = quantize(amount)
    return f"{currency} {cents}"


def quantize(amount: Decimal) -> Decimal:
    return amount.quantize(Decimal("0.01"))
