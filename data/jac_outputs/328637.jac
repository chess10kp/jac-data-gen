"""
    Simplified version from future
    """
def my_round_even(number: Any) -> object {
    import from decimal { Decimal, ROUND_HALF_EVEN }
    d = Decimal.from_float(number).quantize(1, rounding=ROUND_HALF_EVEN);
    return int(d);
}