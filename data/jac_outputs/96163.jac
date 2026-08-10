"""Tell if given parameter is a listing."""
def is_listing(op: object) -> bool {
    return isinstance(op, (list, tuple));
}