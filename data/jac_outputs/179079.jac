""" Set price limits """
def price_range(prices: Any) -> object {
    (min_range, max_range) = prices;
    if not min_range {
        min_range = 0;
    }
    if not max_range {
        max_range = 999999999;
    }
    return (min_range, max_range);
}