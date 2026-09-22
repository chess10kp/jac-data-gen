"""
        TOP most expensive goods
    """
def bigger_price(limit: Any, data: Any) -> object {
    res = sorted(data, key=lambda (k: Any) { k['price']; }, reverse=True);
    return res[:limit];
}