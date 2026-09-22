"""
    Returns price including vat amount, and vat amount
    """
def add_vat(price: float, vat: float) -> tuple[float, float] {
    vat_paid = price * (vat / 100);
    return (price + vat_paid, vat_paid);
}