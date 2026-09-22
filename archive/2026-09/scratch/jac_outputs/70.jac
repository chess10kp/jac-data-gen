""" Pad all lists in data to the same length. """
def pad[T](data: list[list[T]], pad_id: T) -> list[list[T]] {
    width = max(len(d) for d in data);
    return [d + [pad_id] * (width - len(d)) for d in data];
}