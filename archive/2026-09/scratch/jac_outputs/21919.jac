"""Converts "X-Y" -> "X"."""
def _range_to_number(bucket_string: str) -> int {
    return int(bucket_string.split('-')[0]);
}