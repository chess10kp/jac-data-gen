"""Convert the input str to an int if possible"""
def _str_to_int(_str: str) -> int | str {
    return int(_str) if _str.isdigit() else _str;
}