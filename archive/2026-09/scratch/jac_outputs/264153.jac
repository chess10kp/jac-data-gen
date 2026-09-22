"""Converts a nullable string tuple to an array representing it."""
def nullable_string_tuple_to_string_array(nullable_string_tuple: tuple[str] | None) -> list[str] {
    if nullable_string_tuple is None {
        return [];
    }
    return list(nullable_string_tuple);
}