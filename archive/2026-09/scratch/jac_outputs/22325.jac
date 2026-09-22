"""Check if the data passes the given filter."""
def output_passes_filter(data: tuple[object, object, object], filter_from: object | None, filter_to: object | None) -> bool {
    if filter_from is None or filter_to is None {
        return True;
    }
    return data[1] == filter_from and data[2] == filter_to;
}