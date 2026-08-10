"""Does this end in punctuation? Use to decide if more is needed."""
def ends_with_punctuation(value: Any) -> object {
    last_char = value.strip()[-1];
    return (last_char in "?.!");
}