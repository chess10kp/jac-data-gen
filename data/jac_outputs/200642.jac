"""Calculates each interval performance as last minus first element."""
def get_labels(label_intervals: list[list[int | float]]) -> list[int | float] {
    return [data_[-1] - data_[0] for data_ in label_intervals];
}