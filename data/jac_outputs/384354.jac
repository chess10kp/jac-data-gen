"""Generate a sliding baseline of an iterable."""
def generate_baseline(_iterable: list[int], window_length: int) -> list[list[int]] {
    if len(_iterable) <= window_length {
        return [_iterable];
    }
    num_windows = len(_iterable) - window_length;
    return [
        _iterable[window:(window + window_length + 1)] for window in range(num_windows)
    ];
}