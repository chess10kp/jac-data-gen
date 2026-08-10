"""
Pads a list with empty items
Copied from http://stackoverflow.com/a/3438818/3710392
"""
def pad_list(orig_list: list[str], pad_length: int) -> list[str] {
    return orig_list + [''] * (pad_length - len(orig_list));
}