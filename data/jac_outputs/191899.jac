"""Return rating count as an int."""
def to_int(rating_count: int | str) -> int {
    if isinstance(rating_count, int) {
        return rating_count;
    }
    rating_count = rating_count.split()[0];
    if ',' in rating_count {
        return int(rating_count.replace(',', ''));
    }
    return int(rating_count);
}