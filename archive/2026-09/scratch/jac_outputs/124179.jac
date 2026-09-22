"""Calculates the tax on a product

    Formula
    -------
        price * (1 + (tax / 100))
    """
def calculate_tva(price: int | float | str, tva: int | float = 20) -> float {
    return round(float(price) * (1 + tva / 100), 2);
}