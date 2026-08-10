"""format a list into a space-separated string"""
def format_list(list: list[int | str | float | bool]) -> str {
    " ".join(str(tok) for tok in list)
}