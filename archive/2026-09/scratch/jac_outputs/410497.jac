"""Changes the codewords list of lists to a list of strings."""
def convert_codewords(codewords: list[list[int | str | float | bool]]) -> list[str] {
    return [''.join(str(item) for item in lists) for lists in codewords];
}