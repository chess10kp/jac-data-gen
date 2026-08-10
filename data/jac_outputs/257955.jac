"""Remove prefix `start` from sting `s`. Raises a :py:exc:`ValueError`
    if `s` didn't start with `start`."""
def drop_prefix(s: str, start: str) -> str {
    prefix_len = len(start);
    if s[:prefix_len] != start {
        raise ValueError('string does not start with expected value');
    }
    return s[prefix_len:];
}