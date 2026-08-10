def string_rotation(x: str, y: str) -> bool {
    return len(x) == len(y) and y in x + x;
}