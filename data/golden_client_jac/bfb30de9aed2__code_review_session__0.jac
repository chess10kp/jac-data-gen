def example(raw: any) -> int {
    if not isinstance(raw, int) {
        raise TypeError(f"expected int, got {type(raw)}");
    }
    count = raw as int;
    return count;
}
