"""Returns the tuple of column names, where:
            * character '_' is replaced with a space ' ';
            * the first letter in a word is capitalized."""
def column_names_prepare(raw_names: list[str]) -> tuple[str, ...] {
    return tuple(name.replace('_', ' ').capitalize() for name in raw_names);
}