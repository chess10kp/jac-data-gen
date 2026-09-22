"""Get product code from item definition."""
def product_code(d: dict[str, str], i: dict[str, str], r: dict[str, str]) -> str {
    return i.get('product_code', '');
}