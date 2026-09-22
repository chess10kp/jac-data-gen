"""Given a string, find which column index it corresponds to."""
def string_to_index(needle: str, columns: list[str]) -> int {
    for (index, value) in enumerate(columns) {
        if needle == value {
            return index + 1;
        }
    }
    raise ValueError(
        "Value \"{0}\" not found in columns \"{1}\"".format(needle, columns)
    );
}