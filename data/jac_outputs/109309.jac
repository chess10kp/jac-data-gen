"""Element match filter function."""
def elem_match(values: list[object], filter_expr: callable[[object], bool]) -> bool {
    return any(filter_expr(val) for val in values);
}